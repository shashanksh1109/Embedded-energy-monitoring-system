package com.energy.service;

import com.energy.security.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * HubOpsService - what a PAIRED hub does, and what users do with hubs.
 *
 * Hub side (authenticated with its hub key):
 *   registerSensors() - "I found these sensors" -> devices (no zone yet)
 *   pendingCommands() - "anything for me to switch?"
 *   ack()             - "done: FAN is now ON" (or "failed")
 *   reportOutputs()   - "my outputs are: FAN OFF, LED1 OFF, LED2 OFF" (after boot)
 *
 * User side (signed in; ALWAYS filtered by the current organization,
 * because the hub tables have no row-level security):
 *   listHubs()        - hubs with their sensors, outputs and recent commands
 *   sendCommand()     - queue "FAN ON" for one of the organization's hubs
 */
@Service
@RequiredArgsConstructor
public class HubOpsService {

    public record HubIdentity(UUID hubId, UUID orgId, UUID deviceId, String thingName) {}

    public record SensorSpec(String localId, String type, String label) {}

    public static class HubNotFoundException extends RuntimeException {
        public HubNotFoundException() {
            super("Hub not found");
        }
    }

    public static final Set<String> TARGETS = Set.of("FAN", "LED1", "LED2");
    public static final Set<String> SENSOR_TYPES = Set.of("TEMP", "OCCUPANCY", "POWER");

    /** A command not picked up by the hub within this time is dropped. */
    private static final long COMMAND_VALID_SECONDS = 30;

    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final SecureRandom RANDOM = new SecureRandom();

    private final JdbcTemplate jdbc;

    // ------------------------------------------------------------------
    // Hub side
    // ------------------------------------------------------------------

    /**
     * Who is this hub? Null if the key is unknown or the hub is not paired.
     * Also records that the hub is alive (last_seen_at).
     */
    @Transactional
    public HubIdentity authenticate(String hubKey) {
        if (hubKey == null || hubKey.isBlank()) {
            return null;
        }
        List<Map<String, Object>> rows = jdbc.queryForList(
            "UPDATE hubs SET last_seen_at = NOW() WHERE key_hash = ? AND org_id IS NOT NULL " +
            "RETURNING id, org_id, device_id, thing_name",
            HubService.sha256(hubKey));
        if (rows.isEmpty()) {
            return null;
        }
        Map<String, Object> r = rows.get(0);
        return new HubIdentity((UUID) r.get("id"), (UUID) r.get("org_id"),
            (UUID) r.get("device_id"), (String) r.get("thing_name"));
    }

    /**
     * Register the sensors a hub found. Safe to call on every boot: a sensor
     * the hub already reported keeps its device and thing name.
     * Returns, for every sensor: localId, thingName, zoneName (null = not placed).
     */
    @Transactional
    public List<Map<String, Object>> registerSensors(HubIdentity hub, List<SensorSpec> sensors) {
        // devices has row-level security: work as the hub's organization
        // for the rest of this transaction only
        jdbc.queryForObject("SELECT set_config('app.current_org', ?, true)", String.class, hub.orgId().toString());

        List<Map<String, Object>> result = new ArrayList<>();
        for (SensorSpec s : sensors) {
            List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT d.thing_name, z.name AS zone_name FROM hub_sensors hs " +
                "JOIN devices d ON d.id = hs.device_id LEFT JOIN zones z ON z.id = d.zone_id " +
                "WHERE hs.hub_id = ? AND hs.local_id = ?",
                hub.hubId(), s.localId());

            String thingName;
            String zoneName;
            if (!existing.isEmpty()) {
                thingName = (String) existing.get(0).get("thing_name");
                zoneName = (String) existing.get(0).get("zone_name");
            } else {
                thingName = "S" + randomString(6);         // 7 characters, like every device ID
                zoneName = null;
                UUID deviceId = jdbc.queryForObject(
                    "INSERT INTO devices (org_id, thing_name, device_type, display_name, status, claimed_at) " +
                    "VALUES (?, ?, ?, ?, 'ACTIVE', NOW()) RETURNING id",
                    UUID.class, hub.orgId(), thingName, s.type(), s.label());
                jdbc.update("INSERT INTO hub_sensors (hub_id, local_id, device_id) VALUES (?, ?, ?)",
                    hub.hubId(), s.localId(), deviceId);
            }

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("localId", s.localId());
            m.put("thingName", thingName);
            m.put("zoneName", zoneName);
            result.add(m);
        }
        return result;
    }

    /** Commands waiting for this hub, oldest first (expired ones are skipped). */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> pendingCommands(HubIdentity hub) {
        return jdbc.queryForList(
            "SELECT id, target, action FROM hub_commands " +
            "WHERE hub_id = ? AND status = 'PENDING' AND expires_at > NOW() ORDER BY created_at",
            hub.hubId());
    }

    /** The hub reports the result of one command. False if it wasn't pending. */
    @Transactional
    public boolean ack(HubIdentity hub, UUID commandId, boolean success, String message) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "UPDATE hub_commands SET status = ?, completed_at = NOW(), message = ? " +
            "WHERE id = ? AND hub_id = ? AND status = 'PENDING' RETURNING target, action",
            success ? "DONE" : "FAILED", message, commandId, hub.hubId());
        if (rows.isEmpty()) {
            return false;
        }
        if (success) {
            saveOutput(hub.hubId(), (String) rows.get(0).get("target"), (String) rows.get(0).get("action"));
        }
        return true;
    }

    /** The hub reports the real state of its outputs (e.g. all OFF after a reboot). */
    @Transactional
    public void reportOutputs(HubIdentity hub, Map<String, String> states) {
        states.forEach((target, state) -> saveOutput(hub.hubId(), target, state));
    }

    private void saveOutput(UUID hubId, String target, String state) {
        jdbc.update(
            "INSERT INTO hub_outputs (hub_id, target, state, reported_at) VALUES (?, ?, ?, NOW()) " +
            "ON CONFLICT (hub_id, target) DO UPDATE SET state = EXCLUDED.state, reported_at = NOW()",
            hubId, target, state);
    }

    // ------------------------------------------------------------------
    // User side - every query is limited to the CURRENT organization
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public List<Map<String, Object>> listHubs() {
        UUID orgId = TenantContext.get();
        List<Map<String, Object>> hubs = jdbc.queryForList(
            "SELECT id, device_id, thing_name, hardware_model, paired_at, last_seen_at, " +
            "       (last_seen_at > NOW() - INTERVAL '30 seconds') AS online " +
            "FROM hubs WHERE org_id = ? ORDER BY paired_at",
            orgId);

        List<Map<String, Object>> result = new ArrayList<>();
        for (Map<String, Object> h : hubs) {
            UUID hubId = (UUID) h.get("id");

            Map<String, Object> hub = new LinkedHashMap<>();
            hub.put("hubDeviceId", h.get("device_id"));
            hub.put("thingName", h.get("thing_name"));
            hub.put("model", h.get("hardware_model"));
            hub.put("pairedAt", h.get("paired_at"));
            hub.put("lastSeenAt", h.get("last_seen_at"));
            hub.put("online", Boolean.TRUE.equals(h.get("online")));

            // devices/zones have row-level security; the current org is already set
            hub.put("sensors", jdbc.queryForList(
                "SELECT d.id AS device_id, hs.local_id, d.thing_name, d.device_type, d.display_name, " +
                "       z.id AS zone_id, z.name AS zone_name, d.last_seen_at " +
                "FROM hub_sensors hs JOIN devices d ON d.id = hs.device_id " +
                "LEFT JOIN zones z ON z.id = d.zone_id WHERE hs.hub_id = ? ORDER BY hs.local_id",
                hubId));

            hub.put("outputs", jdbc.queryForList(
                "SELECT target, state, reported_at FROM hub_outputs WHERE hub_id = ? ORDER BY target",
                hubId));

            hub.put("recentCommands", jdbc.queryForList(
                "SELECT id, target, action, requested_by, created_at, completed_at, message, " +
                "       CASE WHEN status = 'PENDING' AND expires_at <= NOW() THEN 'EXPIRED' ELSE status END AS status " +
                "FROM hub_commands WHERE hub_id = ? ORDER BY created_at DESC LIMIT 10",
                hubId));

            result.add(hub);
        }
        return result;
    }

    /** Queue a command for one of the CURRENT organization's hubs. */
    @Transactional
    public UUID sendCommand(UUID hubDeviceId, String target, String action, String requestedBy) {
        List<UUID> hubIds = jdbc.query(
            "SELECT id FROM hubs WHERE device_id = ? AND org_id = ?",
            (rs, rowNum) -> rs.getObject(1, UUID.class),
            hubDeviceId, TenantContext.get());
        if (hubIds.isEmpty()) {
            throw new HubNotFoundException();          // not ours, or doesn't exist
        }
        return jdbc.queryForObject(
            "INSERT INTO hub_commands (hub_id, target, action, requested_by, expires_at) " +
            "VALUES (?, ?, ?, ?, ?) RETURNING id",
            UUID.class, hubIds.get(0), target, action, requestedBy,
            OffsetDateTime.now().plusSeconds(COMMAND_VALID_SECONDS));
    }

    private static String randomString(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(ALPHABET.charAt(RANDOM.nextInt(ALPHABET.length())));
        }
        return sb.toString();
    }
}