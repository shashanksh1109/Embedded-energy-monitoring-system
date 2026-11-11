package com.energy.service;

import com.energy.security.TenantContext;
import com.energy.service.HubOpsService.HubIdentity;
import com.energy.service.HubOpsService.HubNotFoundException;
import com.energy.service.HubOpsService.SensorSpec;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * HubConfigService - which hardware is wired to which pin, set in the
 * dashboard and downloaded by the hub.
 *
 * Config format (JSON):
 *   outputs: [{key: "fan", name: "Fan", kind: FAN|LED|RELAY, gpio: 18, activeHigh: true}]
 *   sensors: [{key: "room", name: "Room climate", driver: SOC_TEMP|BME280|INA219|PIR,
 *              i2cAddress: 118 (BME280/INA219) | gpio: 23 (PIR)}]
 *
 * Every config is VALIDATED here before it is saved, so a bad config can
 * never reach a hub: only free GPIO pins, no pin or I2C address used twice,
 * every pin either an input or an output.
 */
@Service
@RequiredArgsConstructor
public class HubConfigService {

    public static class InvalidConfigException extends RuntimeException {
        public InvalidConfigException(String message) {
            super(message);
        }
    }

    /**
     * GPIO pins (BCM numbers) a customer may use on a Raspberry Pi.
     * Not offered: 0-1 (HAT ID EEPROM), 2-3 (I2C: sensors, OLED),
     * 7-11 (SPI), 14-15 (UART serial).
     */
    public static final List<Integer> ALLOWED_GPIO =
        List.of(4, 5, 6, 12, 13, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27);

    public static final Set<String> OUTPUT_KINDS = Set.of("FAN", "LED", "RELAY");

    /** Supported sensor drivers and the reading type each produces. */
    public static final Map<String, String> DRIVER_TYPES = Map.of(
        "SOC_TEMP", "TEMP",       // the Pi's own CPU temperature
        "BME280", "TEMP",         // room temperature (+ humidity later), I2C 0x76/0x77
        "INA219", "POWER",        // current/power, I2C 0x40-0x4F
        "PIR", "OCCUPANCY"        // motion sensor on a GPIO pin
    );

    private static final int MAX_ITEMS = 16;
    private static final String KEY_PATTERN = "[a-z0-9_]{1,32}";

    private final JdbcTemplate jdbc;
    private final HubOpsService hubOps;
    private final ObjectMapper json;

    // ------------------------------------------------------------------
    // Users (current organization only)
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public Map<String, Object> getForUser(UUID hubDeviceId) {
        HubIdentity hub = findHub(hubDeviceId);
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT version, config::text AS config, updated_by, updated_at, applied_version, applied_at, " +
            "       scan::text AS scan, scan_at FROM hub_configs WHERE hub_id = ?",
            hub.hubId());

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("allowedGpio", ALLOWED_GPIO);
        out.put("drivers", DRIVER_TYPES);
        if (rows.isEmpty()) {
            out.put("version", 0);
            out.put("config", defaultConfig());
            out.put("appliedVersion", null);
            out.put("scan", null);
            return out;
        }
        Map<String, Object> r = rows.get(0);
        out.put("version", r.get("version"));
        out.put("config", readJson((String) r.get("config")));
        out.put("updatedBy", r.get("updated_by"));
        out.put("updatedAt", r.get("updated_at"));
        out.put("appliedVersion", r.get("applied_version"));
        out.put("appliedAt", r.get("applied_at"));
        out.put("scan", r.get("scan") == null ? null : readJson((String) r.get("scan")));
        out.put("scanAt", r.get("scan_at"));
        return out;
    }

    /**
     * Validate and save a new config (version + 1). Sensors in the config are
     * registered as devices right away, so they can be placed in zones before
     * the hub has even downloaded the new version.
     */
    @Transactional
    public Map<String, Object> save(UUID hubDeviceId, JsonNode config, String updatedBy) {
        HubIdentity hub = findHub(hubDeviceId);
        ObjectNode clean = validate(config);

        jdbc.queryForObject(
            "INSERT INTO hub_configs (hub_id, version, config, updated_by, updated_at) " +
            "VALUES (?, 1, ?::jsonb, ?, NOW()) " +
            "ON CONFLICT (hub_id) DO UPDATE SET version = hub_configs.version + 1, " +
            "  config = EXCLUDED.config, updated_by = EXCLUDED.updated_by, updated_at = NOW() " +
            "RETURNING version",
            Integer.class, hub.hubId(), clean.toString(), updatedBy);

        List<SensorSpec> specs = new ArrayList<>();
        for (JsonNode s : clean.withArray("sensors")) {
            specs.add(new SensorSpec(s.get("key").asText(), s.get("type").asText(), s.get("name").asText()));
        }
        hubOps.registerSensors(hub, specs);

        return getForUser(hubDeviceId);
    }

    /** Output keys of a hub's current config (for validating commands). */
    @Transactional(readOnly = true)
    public Set<String> outputKeys(UUID hubDeviceId) {
        HubIdentity hub = findHub(hubDeviceId);
        Set<String> keys = new HashSet<>();
        for (JsonNode o : configFor(hub).withArray("outputs")) {
            keys.add(o.get("key").asText());
        }
        return keys;
    }

    // ------------------------------------------------------------------
    // Hub side
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public Map<String, Object> getForHub(HubIdentity hub) {
        List<Integer> versions = jdbc.query(
            "SELECT version FROM hub_configs WHERE hub_id = ?",
            (rs, rowNum) -> rs.getInt(1), hub.hubId());
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("version", versions.isEmpty() ? 0 : versions.get(0));
        out.put("config", configFor(hub));
        return out;
    }

    /** The hub applied a config version and reports what its scan found. */
    @Transactional
    public void markApplied(HubIdentity hub, int version, JsonNode scan) {
        jdbc.update(
            "INSERT INTO hub_configs (hub_id, version, config, applied_version, applied_at, scan, scan_at) " +
            "VALUES (?, 0, ?::jsonb, ?, NOW(), ?::jsonb, NOW()) " +
            "ON CONFLICT (hub_id) DO UPDATE SET applied_version = EXCLUDED.applied_version, " +
            "  applied_at = NOW(), scan = EXCLUDED.scan, scan_at = NOW()",
            hub.hubId(), defaultConfig().toString(), version, scan == null ? null : scan.toString());
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /** The hub, only if it belongs to the CURRENT organization (no RLS on hubs). */
    private HubIdentity findHub(UUID hubDeviceId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT id, org_id, device_id, thing_name FROM hubs WHERE device_id = ? AND org_id = ?",
            hubDeviceId, TenantContext.get());
        if (rows.isEmpty()) {
            throw new HubNotFoundException();
        }
        Map<String, Object> r = rows.get(0);
        return new HubIdentity((UUID) r.get("id"), (UUID) r.get("org_id"),
            (UUID) r.get("device_id"), (String) r.get("thing_name"));
    }

    private ObjectNode configFor(HubIdentity hub) {
        List<String> rows = jdbc.query(
            "SELECT config::text FROM hub_configs WHERE hub_id = ?",
            (rs, rowNum) -> rs.getString(1), hub.hubId());
        return rows.isEmpty() ? defaultConfig() : (ObjectNode) readJson(rows.get(0));
    }

    /** A new hub reports its own CPU temperature and has no outputs. */
    private ObjectNode defaultConfig() {
        ObjectNode c = json.createObjectNode();
        c.putArray("outputs");
        ObjectNode soc = c.putArray("sensors").addObject();
        soc.put("key", "soc_temp");
        soc.put("name", "Pi CPU temperature");
        soc.put("type", "TEMP");
        soc.put("driver", "SOC_TEMP");
        return c;
    }

    private JsonNode readJson(String text) {
        try {
            return json.readTree(text);
        } catch (Exception e) {
            throw new IllegalStateException("Stored JSON is invalid", e);
        }
    }

    /** Check everything and return a clean copy (unknown fields are dropped). */
    private ObjectNode validate(JsonNode in) {
        if (in == null || !in.isObject()) {
            throw new InvalidConfigException("Config must be a JSON object");
        }
        JsonNode outputsIn = in.path("outputs");
        JsonNode sensorsIn = in.path("sensors");
        if (!outputsIn.isArray() || !sensorsIn.isArray()) {
            throw new InvalidConfigException("Config needs 'outputs' and 'sensors' lists");
        }
        if (outputsIn.size() > MAX_ITEMS || sensorsIn.size() > MAX_ITEMS) {
            throw new InvalidConfigException("At most " + MAX_ITEMS + " outputs and " + MAX_ITEMS + " sensors");
        }

        Set<String> keys = new HashSet<>();
        Set<Integer> pins = new HashSet<>();
        Set<Integer> i2c = new HashSet<>();
        ObjectNode clean = json.createObjectNode();

        ArrayNode outputs = clean.putArray("outputs");
        for (JsonNode o : outputsIn) {
            String key = requireKey(o, keys);
            String kind = o.path("kind").asText("").toUpperCase();
            if (!OUTPUT_KINDS.contains(kind)) {
                throw new InvalidConfigException("Output '" + key + "': kind must be one of " + OUTPUT_KINDS);
            }
            int gpio = requireGpio(o, pins, "Output '" + key + "'");
            ObjectNode c = outputs.addObject();
            c.put("key", key);
            c.put("name", name(o, key));
            c.put("kind", kind);
            c.put("gpio", gpio);
            c.put("activeHigh", o.path("activeHigh").asBoolean(true));
        }

        ArrayNode sensors = clean.putArray("sensors");
        boolean hasSoc = false;
        for (JsonNode s : sensorsIn) {
            String key = requireKey(s, keys);
            String driver = s.path("driver").asText("").toUpperCase();
            if (!DRIVER_TYPES.containsKey(driver)) {
                throw new InvalidConfigException("Sensor '" + key + "': driver must be one of " + DRIVER_TYPES.keySet());
            }
            ObjectNode c = sensors.addObject();
            c.put("key", key);
            c.put("name", name(s, key));
            c.put("type", DRIVER_TYPES.get(driver));
            c.put("driver", driver);

            switch (driver) {
                case "SOC_TEMP" -> {
                    if (hasSoc) {
                        throw new InvalidConfigException("Only one CPU temperature sensor is possible");
                    }
                    hasSoc = true;
                }
                case "BME280" -> c.put("i2cAddress", requireI2c(s, i2c, key, Set.of(0x76, 0x77)));
                case "INA219" -> c.put("i2cAddress", requireI2c(s, i2c, key, rangeSet(0x40, 0x4F)));
                case "PIR" -> c.put("gpio", requireGpio(s, pins, "Sensor '" + key + "'"));
                default -> throw new InvalidConfigException("Unknown driver " + driver);
            }
        }
        return clean;
    }

    private static String requireKey(JsonNode item, Set<String> used) {
        String key = item.path("key").asText("");
        if (!key.matches(KEY_PATTERN)) {
            throw new InvalidConfigException("Every item needs a key of 1-32 characters a-z, 0-9, _ (got '" + key + "')");
        }
        if (!used.add(key)) {
            throw new InvalidConfigException("Key '" + key + "' is used twice");
        }
        return key;
    }

    private static String name(JsonNode item, String key) {
        String name = item.path("name").asText(key).trim();
        if (name.isEmpty()) {
            name = key;
        }
        return name.length() > 60 ? name.substring(0, 60) : name;
    }

    private static int requireGpio(JsonNode item, Set<Integer> used, String what) {
        if (!item.path("gpio").isInt()) {
            throw new InvalidConfigException(what + ": gpio must be a number");
        }
        int gpio = item.get("gpio").asInt();
        if (!ALLOWED_GPIO.contains(gpio)) {
            throw new InvalidConfigException(what + ": GPIO " + gpio + " can't be used. Free pins: " + ALLOWED_GPIO);
        }
        if (!used.add(gpio)) {
            throw new InvalidConfigException(what + ": GPIO " + gpio + " is already used by another item");
        }
        return gpio;
    }

    private static int requireI2c(JsonNode item, Set<Integer> used, String key, Set<Integer> allowed) {
        if (!item.path("i2cAddress").isInt()) {
            throw new InvalidConfigException("Sensor '" + key + "': i2cAddress must be a number (e.g. 118 = 0x76)");
        }
        int addr = item.get("i2cAddress").asInt();
        if (!allowed.contains(addr)) {
            throw new InvalidConfigException("Sensor '" + key + "': I2C address " + addr + " is not valid for this sensor");
        }
        if (!used.add(addr)) {
            throw new InvalidConfigException("Sensor '" + key + "': I2C address " + addr + " is already used");
        }
        return addr;
    }

    private static Set<Integer> rangeSet(int from, int to) {
        Set<Integer> s = new HashSet<>();
        for (int i = from; i <= to; i++) {
            s.add(i);
        }
        return s;
    }
}