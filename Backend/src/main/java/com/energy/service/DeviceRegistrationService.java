package com.energy.service;

import com.energy.dto.DeviceResponse;
import com.energy.model.Device;
import com.energy.model.Zone;
import com.energy.repository.DeviceRepository;
import com.energy.repository.ZoneRepository;
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
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * DeviceRegistrationService - adding a device to a zone, with a claim code.
 *
 * 1. register(): an OWNER/ADMIN adds a device to one of their zones.
 *    The device is created as PENDING with a generated thing name, and a
 *    one-time CLAIM CODE is returned (shown to the user once).
 *    Only a SHA-256 hash of the code is stored, like a password.
 *
 * 2. claim(): the physical device (or the person setting it up) sends the
 *    code. If it matches an unused, unexpired claim, the device becomes
 *    ACTIVE and learns its thing name. From then on the gateway accepts
 *    its readings, and they land in the right organization.
 *
 * Product flow (device -> dashboard), for devices made in a factory:
 *
 * 3. claimFactoryDevice(): the device already knows its thing name (set at
 *    the factory) and its claim code is printed on its label. The customer
 *    types the code in the dashboard; the device is moved from the factory
 *    inventory into the customer's organization and zone, already ACTIVE.
 */
@Service
@RequiredArgsConstructor
public class DeviceRegistrationService {

    public static class ZoneNotFoundException extends RuntimeException {
        public ZoneNotFoundException() {
            super("Zone not found");
        }
    }

    /** Thrown when a factory claim code is wrong or the device was already claimed. */
    public static class InvalidCodeException extends RuntimeException {
        public InvalidCodeException() {
            super("Invalid or already used device code");
        }
    }

    public record Registration(DeviceResponse device, String claimCode, OffsetDateTime claimExpiresAt) {}

    public record ClaimResult(String thingName, String deviceType, String zoneName) {}

    /** How long a claim code stays valid. */
    private static final long CLAIM_VALID_HOURS = 24;

    /** No 0/O, 1/I/L: codes are typed by people. */
    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

    private static final SecureRandom RANDOM = new SecureRandom();

    private final ZoneRepository zoneRepository;
    private final DeviceRepository deviceRepository;
    private final JdbcTemplate jdbc;

    @Transactional
    public Registration register(UUID zoneId, String deviceType, String displayName) {
        // Row-level security: only the current organization's zones are found
        Zone zone = zoneRepository.findById(zoneId).orElseThrow(ZoneNotFoundException::new);

        Device device = Device.builder()
            .orgId(TenantContext.get())
            .zone(zone)
            .thingName(newThingName())
            .deviceType(deviceType)
            .displayName(displayName)
            .status(Device.Status.PENDING)
            .build();
        device = deviceRepository.saveAndFlush(device);

        String code = randomString(8);
        OffsetDateTime expiresAt = OffsetDateTime.now().plusHours(CLAIM_VALID_HOURS);
        jdbc.update(
            "INSERT INTO device_claims (code_hash, device_id, org_id, expires_at) VALUES (?, ?, ?, ?)",
            sha256(normalize(code)), device.getId(), device.getOrgId(), expiresAt);

        String shown = code.substring(0, 4) + "-" + code.substring(4);   // e.g. K7QM-4XPA
        return new Registration(DeviceResponse.from(device), shown, expiresAt);
    }

    /**
     * Returns the claimed device's details, or null if the code is wrong,
     * already used or expired.
     */
    @Transactional
    public ClaimResult claim(String code) {
        String hash = sha256(normalize(code));

        // FOR UPDATE: two simultaneous claims with the same code can't both win
        List<Map<String, Object>> claims = jdbc.queryForList(
            "SELECT device_id, org_id FROM device_claims " +
            "WHERE code_hash = ? AND used_at IS NULL AND expires_at > NOW() FOR UPDATE",
            hash);
        if (claims.isEmpty()) {
            return null;
        }
        UUID deviceId = (UUID) claims.get(0).get("device_id");
        UUID orgId = (UUID) claims.get(0).get("org_id");

        // devices has row-level security: act as the device's organization
        // for the rest of this transaction only
        jdbc.queryForObject("SELECT set_config('app.current_org', ?, true)", String.class, orgId.toString());

        List<Map<String, Object>> activated = jdbc.queryForList(
            "UPDATE devices SET status = 'ACTIVE', claimed_at = NOW() " +
            "WHERE id = ? AND status = 'PENDING' RETURNING thing_name, device_type, zone_id",
            deviceId);
        if (activated.isEmpty()) {
            return null;
        }

        jdbc.update("UPDATE device_claims SET used_at = NOW() WHERE code_hash = ?", hash);

        Map<String, Object> d = activated.get(0);
        String zoneName = jdbc.queryForObject(
            "SELECT name FROM zones WHERE id = ?", String.class, d.get("zone_id"));
        return new ClaimResult((String) d.get("thing_name"), (String) d.get("device_type"), zoneName);
    }

    /**
     * Product flow: add a factory-made device to one of the organization's
     * zones, using the code printed on its label.
     *
     * factory_devices is the manufacturer's inventory (no row-level security:
     * it belongs to no customer yet). It stores only a HASH of each label
     * code. FOR UPDATE makes two customers typing the same code at the same
     * moment wait for each other; only the first one gets the device.
     */
    @Transactional
    public DeviceResponse claimFactoryDevice(String code, UUID zoneId, String displayName) {
        Zone zone = zoneRepository.findById(zoneId).orElseThrow(ZoneNotFoundException::new);

        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT thing_name, device_type FROM factory_devices " +
            "WHERE claim_code_hash = ? AND claimed_at IS NULL FOR UPDATE",
            sha256(normalize(code)));
        if (rows.isEmpty()) {
            throw new InvalidCodeException();
        }
        String thingName = (String) rows.get(0).get("thing_name");
        String deviceType = (String) rows.get(0).get("device_type");

        Device device = Device.builder()
            .orgId(TenantContext.get())
            .zone(zone)
            .thingName(thingName)
            .deviceType(deviceType)
            .displayName(displayName)
            .status(Device.Status.ACTIVE)          // the device is already sending
            .claimedAt(OffsetDateTime.now())
            .build();
        device = deviceRepository.saveAndFlush(device);

        jdbc.update(
            "UPDATE factory_devices SET claimed_at = NOW(), device_id = ? WHERE thing_name = ?",
            device.getId(), thingName);

        return DeviceResponse.from(device);
    }

    /**
     * 7 characters, because the device's 20-byte packet has an 8-byte ID
     * field that ends with a null byte. "D" + 6 random characters gives
     * about a billion possible names; a clash is rejected by the database's
     * UNIQUE constraint.
     */
    private static String newThingName() {
        return "D" + randomString(6);
    }

    private static String randomString(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }

    /** "k7qm-4xpa " -> "K7QM4XPA" (people type codes in different ways). */
    private static String normalize(String code) {
        return code == null ? "" : code.toUpperCase().replaceAll("[^A-Z0-9]", "");
    }

    private static String sha256(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                .digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);       // every Java has SHA-256
        }
    }
}