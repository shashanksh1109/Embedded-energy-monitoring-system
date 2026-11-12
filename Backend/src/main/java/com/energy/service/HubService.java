package com.energy.service;

import com.energy.model.Device;
import com.energy.repository.DeviceRepository;
import com.energy.security.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * HubService - pairing a Raspberry Pi hub with an organization.
 *
 * The hub SHOWS a code; the customer TYPES it in the dashboard
 * (the "enter the code on your TV" pattern):
 *
 *   start()  - hub, no login:   gets a secret hub key + a 10-minute pairing code
 *   status() - hub, with key:   "am I paired yet?"
 *   pair()   - signed-in OWNER/ADMIN types the code: the hub joins their
 *              organization and gets a device row of type HUB
 */
@Service
@RequiredArgsConstructor
public class HubService {

    public record PairingStart(String hubKey, String pairingCode, OffsetDateTime expiresAt) {}

    public record HubStatus(boolean paired, boolean codeExpired, String thingName, String organizationName) {}

    public record PairResult(UUID hubDeviceId, String thingName) {}

    public static class InvalidPairingCodeException extends RuntimeException {
        public InvalidPairingCodeException() {
            super("Invalid or expired pairing code");
        }
    }

    /** How long a pairing code shown on the hub stays valid. */
    private static final long CODE_VALID_MINUTES = 10;

    /** No 0/O, 1/I/L: the code is read off a small screen and typed. */
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

    private static final SecureRandom RANDOM = new SecureRandom();

    private final JdbcTemplate jdbc;
    private final DeviceRepository deviceRepository;

    /** A new, unpaired hub asks for a pairing code. */
    @Transactional
    public PairingStart start(String model) {
        String hubKey = newHubKey();
        String code = randomString(6);
        for (int attempt = 0; attempt < 5; attempt++) {
            Integer inUse = jdbc.queryForObject(
                "SELECT count(*) FROM hubs WHERE pairing_code_hash = ?", Integer.class, sha256(code));
            if (inUse == null || inUse == 0) {
                break;
            }
            code = randomString(6);               // extremely rare: pick another
        }

        OffsetDateTime expiresAt = OffsetDateTime.now().plusMinutes(CODE_VALID_MINUTES);
        jdbc.update(
            "INSERT INTO hubs (key_hash, pairing_code_hash, pairing_expires_at, hardware_model) VALUES (?, ?, ?, ?)",
            sha256(hubKey), sha256(code), expiresAt, model);

        return new PairingStart(hubKey, code.substring(0, 3) + "-" + code.substring(3), expiresAt);
    }

    /** The hub checks whether someone entered its code. Null = unknown key. */
    @Transactional(readOnly = true)
    public HubStatus status(String hubKey) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT h.thing_name, o.name AS org_name, " +
            "       (h.pairing_expires_at IS NOT NULL AND h.pairing_expires_at < NOW()) AS expired " +
            "FROM hubs h LEFT JOIN organizations o ON o.id = h.org_id " +
            "WHERE h.key_hash = ?",
            sha256(hubKey));
        if (rows.isEmpty()) {
            return null;
        }
        Map<String, Object> r = rows.get(0);
        String orgName = (String) r.get("org_name");
        if (orgName != null) {
            return new HubStatus(true, false, (String) r.get("thing_name"), orgName);
        }
        return new HubStatus(false, Boolean.TRUE.equals(r.get("expired")), null, null);
    }

    /**
     * A signed-in OWNER/ADMIN entered the code shown on a hub: the hub joins
     * the CURRENT organization. FOR UPDATE: two people typing the same code at
     * the same moment can't both get the hub.
     */
    @Transactional
    public PairResult pair(String code) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT id FROM hubs WHERE pairing_code_hash = ? AND org_id IS NULL " +
            "AND pairing_expires_at > NOW() FOR UPDATE",
            sha256(normalize(code)));
        if (rows.isEmpty()) {
            throw new InvalidPairingCodeException();
        }
        UUID hubId = (UUID) rows.get(0).get("id");

        Device hub = Device.builder()
            .orgId(TenantContext.get())
            .thingName("H" + randomString(6))          // 7 characters, like every device ID
            .deviceType("HUB")
            .displayName("Raspberry Pi hub")
            .status(Device.Status.ACTIVE)
            .claimedAt(OffsetDateTime.now())
            .build();
        hub = deviceRepository.saveAndFlush(hub);

        jdbc.update(
            "UPDATE hubs SET org_id = ?, device_id = ?, thing_name = ?, paired_at = NOW(), " +
            "pairing_code_hash = NULL WHERE id = ?",
            hub.getOrgId(), hub.getId(), hub.getThingName(), hubId);

        return new PairResult(hub.getId(), hub.getThingName());
    }

    /** 32 random bytes as URL-safe text: the hub's long-term secret. */
    private static String newHubKey() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String randomString(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }

    /** "4k7-qm9 " -> "4K7QM9" */
    private static String normalize(String code) {
        return code == null ? "" : code.toUpperCase().replaceAll("[^A-Z0-9]", "");
    }

    static String sha256(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}