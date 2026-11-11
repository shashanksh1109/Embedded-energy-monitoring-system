package com.energy.controller;

import com.energy.service.HubOpsService;
import com.energy.service.HubOpsService.HubIdentity;
import com.energy.service.HubOpsService.HubNotFoundException;
import com.energy.service.HubOpsService.SensorSpec;
import com.energy.service.HubService;
import com.energy.service.HubService.HubStatus;
import com.energy.service.HubService.InvalidPairingCodeException;
import com.energy.service.HubService.PairResult;
import com.energy.service.HubService.PairingStart;
import com.energy.service.MembershipService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * HubController - Raspberry Pi hub pairing.
 *
 *   POST /api/hubs/start    (hub, no login)      -> {hubKey, pairingCode, expiresAt, pollSeconds}
 *   GET  /api/hubs/status   (hub, X-Hub-Key)     -> {paired, codeExpired, thingName, organizationName}
 *   POST /api/hubs/pair     (OWNER/ADMIN login)  -> {hubDeviceId, thingName}
 *
 * Paired hub (X-Hub-Key):
 *   POST /api/hubs/sensors              -> register discovered sensors
 *   GET  /api/hubs/commands             -> pending FAN/LED commands
 *   POST /api/hubs/commands/{id}/ack    -> report a command's result
 *   POST /api/hubs/outputs              -> report real output states
 *
 * Signed-in users (current organization only):
 *   GET  /api/hubs                      -> hubs with sensors, outputs, recent commands
 *   POST /api/hubs/{hubDeviceId}/commands  (OWNER/ADMIN) -> queue FAN/LED1/LED2 ON/OFF
 */
@RestController
@RequestMapping("/api/hubs")
@RequiredArgsConstructor
public class HubController {

    /** Header the hub uses to prove who it is. */
    public static final String HUB_KEY_HEADER = "X-Hub-Key";

    private final HubService hubService;
    private final HubOpsService hubOps;
    private final MembershipService membershipService;

    /** Most sensors one hub may register. */
    private static final int MAX_SENSORS = 16;

    @Data
    public static class StartRequest {
        private String model;
    }

    @Data
    public static class PairRequest {
        private String code;
    }

    @Data
    public static class SensorItem {
        private String localId;
        private String type;
        private String label;
    }

    @Data
    public static class SensorsRequest {
        private List<SensorItem> sensors;
    }

    @Data
    public static class AckRequest {
        private Boolean success;
        private String message;
    }

    @Data
    public static class CommandRequest {
        private String target;
        private String action;
    }

    @PostMapping("/start")
    public ResponseEntity<?> start(@RequestBody(required = false) StartRequest body) {
        String model = body == null || body.getModel() == null ? null : body.getModel().trim();
        if (model != null && model.length() > 64) {
            model = model.substring(0, 64);
        }
        PairingStart s = hubService.start(model);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
            "hubKey", s.hubKey(),
            "pairingCode", s.pairingCode(),
            "expiresAt", s.expiresAt(),
            "pollSeconds", 3
        ));
    }

    @GetMapping("/status")
    public ResponseEntity<?> status(@RequestHeader(value = HUB_KEY_HEADER, required = false) String hubKey) {
        if (hubKey == null || hubKey.isBlank()) {
            return error(HttpStatus.UNAUTHORIZED, "Missing " + HUB_KEY_HEADER);
        }
        HubStatus s = hubService.status(hubKey);
        if (s == null) {
            return error(HttpStatus.UNAUTHORIZED, "Unknown hub key");
        }
        Map<String, Object> body = new HashMap<>();          // HashMap: values may be null
        body.put("paired", s.paired());
        body.put("codeExpired", s.codeExpired());
        body.put("thingName", s.thingName());
        body.put("organizationName", s.organizationName());
        return ResponseEntity.ok(body);
    }

    @PostMapping("/pair")
    public ResponseEntity<?> pair(@RequestBody PairRequest body, Principal principal) {
        if (!membershipService.canManage(principal)) {
            return error(HttpStatus.FORBIDDEN, "Only an owner or admin can add hubs");
        }
        if (body.getCode() == null || body.getCode().isBlank()) {
            return error(HttpStatus.BAD_REQUEST, "code is required");
        }
        try {
            PairResult r = hubService.pair(body.getCode());
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "hubDeviceId", r.hubDeviceId(),
                "thingName", r.thingName()
            ));
        } catch (InvalidPairingCodeException e) {
            return error(HttpStatus.NOT_FOUND, e.getMessage());
        } catch (DataIntegrityViolationException e) {
            return error(HttpStatus.CONFLICT, "Could not pair the hub, please try again");
        }
    }

    // ------------------------------------------------------------------
    // Paired hub endpoints (authenticated with X-Hub-Key)
    // ------------------------------------------------------------------

    @PostMapping("/sensors")
    public ResponseEntity<?> registerSensors(@RequestHeader(value = HUB_KEY_HEADER, required = false) String hubKey,
                                             @RequestBody SensorsRequest body) {
        HubIdentity hub = hubOps.authenticate(hubKey);
        if (hub == null) {
            return error(HttpStatus.UNAUTHORIZED, "Unknown or unpaired hub");
        }
        List<SensorItem> items = body.getSensors() == null ? List.of() : body.getSensors();
        if (items.size() > MAX_SENSORS) {
            return error(HttpStatus.BAD_REQUEST, "At most " + MAX_SENSORS + " sensors per hub");
        }
        List<SensorSpec> specs = new ArrayList<>();
        for (SensorItem s : items) {
            String localId = s.getLocalId() == null ? "" : s.getLocalId().trim();
            String type = s.getType() == null ? "" : s.getType().trim().toUpperCase();
            String label = s.getLabel() == null ? localId : s.getLabel().trim();
            if (!localId.matches("[a-z0-9_]{1,64}")) {
                return error(HttpStatus.BAD_REQUEST, "localId must be 1-64 of a-z, 0-9, _");
            }
            if (!HubOpsService.SENSOR_TYPES.contains(type)) {
                return error(HttpStatus.BAD_REQUEST, "type must be one of " + HubOpsService.SENSOR_TYPES);
            }
            specs.add(new SensorSpec(localId, type, label.length() > 120 ? label.substring(0, 120) : label));
        }
        return ResponseEntity.ok(Map.of("sensors", hubOps.registerSensors(hub, specs)));
    }

    @GetMapping("/commands")
    public ResponseEntity<?> pendingCommands(@RequestHeader(value = HUB_KEY_HEADER, required = false) String hubKey) {
        HubIdentity hub = hubOps.authenticate(hubKey);
        if (hub == null) {
            return error(HttpStatus.UNAUTHORIZED, "Unknown or unpaired hub");
        }
        return ResponseEntity.ok(Map.of("commands", hubOps.pendingCommands(hub)));
    }

    @PostMapping("/commands/{commandId}/ack")
    public ResponseEntity<?> ack(@RequestHeader(value = HUB_KEY_HEADER, required = false) String hubKey,
                                 @PathVariable UUID commandId,
                                 @RequestBody AckRequest body) {
        HubIdentity hub = hubOps.authenticate(hubKey);
        if (hub == null) {
            return error(HttpStatus.UNAUTHORIZED, "Unknown or unpaired hub");
        }
        String message = body.getMessage() == null ? null
            : body.getMessage().substring(0, Math.min(255, body.getMessage().length()));
        boolean ok = hubOps.ack(hub, commandId, Boolean.TRUE.equals(body.getSuccess()), message);
        if (!ok) {
            return error(HttpStatus.NOT_FOUND, "Command not found or already completed");
        }
        return ResponseEntity.ok(Map.of("acknowledged", true));
    }

    @PostMapping("/outputs")
    public ResponseEntity<?> reportOutputs(@RequestHeader(value = HUB_KEY_HEADER, required = false) String hubKey,
                                           @RequestBody Map<String, String> states) {
        HubIdentity hub = hubOps.authenticate(hubKey);
        if (hub == null) {
            return error(HttpStatus.UNAUTHORIZED, "Unknown or unpaired hub");
        }
        for (Map.Entry<String, String> e : states.entrySet()) {
            if (!HubOpsService.TARGETS.contains(e.getKey())
                    || !("ON".equals(e.getValue()) || "OFF".equals(e.getValue()))) {
                return error(HttpStatus.BAD_REQUEST, "Outputs must be FAN/LED1/LED2 with ON or OFF");
            }
        }
        hubOps.reportOutputs(hub, states);
        return ResponseEntity.ok(Map.of("saved", states.size()));
    }

    // ------------------------------------------------------------------
    // Signed-in users (current organization only)
    // ------------------------------------------------------------------

    @GetMapping
    public ResponseEntity<?> listHubs() {
        return ResponseEntity.ok(hubOps.listHubs());
    }

    @PostMapping("/{hubDeviceId}/commands")
    public ResponseEntity<?> sendCommand(@PathVariable UUID hubDeviceId,
                                         @RequestBody CommandRequest body,
                                         Principal principal) {
        if (!membershipService.canManage(principal)) {
            return error(HttpStatus.FORBIDDEN, "Only an owner or admin can control hubs");
        }
        String target = body.getTarget() == null ? "" : body.getTarget().trim().toUpperCase();
        String action = body.getAction() == null ? "" : body.getAction().trim().toUpperCase();
        if (!HubOpsService.TARGETS.contains(target)) {
            return error(HttpStatus.BAD_REQUEST, "target must be one of " + HubOpsService.TARGETS);
        }
        if (!"ON".equals(action) && !"OFF".equals(action)) {
            return error(HttpStatus.BAD_REQUEST, "action must be ON or OFF");
        }
        try {
            UUID id = hubOps.sendCommand(hubDeviceId, target, action, principal.getName());
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(Map.of("commandId", id, "status", "PENDING"));
        } catch (HubNotFoundException e) {
            return error(HttpStatus.NOT_FOUND, e.getMessage());
        }
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}