package com.energy.controller;

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
import java.util.HashMap;
import java.util.Map;

/**
 * HubController - Raspberry Pi hub pairing.
 *
 *   POST /api/hubs/start    (hub, no login)      -> {hubKey, pairingCode, expiresAt, pollSeconds}
 *   GET  /api/hubs/status   (hub, X-Hub-Key)     -> {paired, codeExpired, thingName, organizationName}
 *   POST /api/hubs/pair     (OWNER/ADMIN login)  -> {hubDeviceId, thingName}
 */
@RestController
@RequestMapping("/api/hubs")
@RequiredArgsConstructor
public class HubController {

    /** Header the hub uses to prove who it is. */
    public static final String HUB_KEY_HEADER = "X-Hub-Key";

    private final HubService hubService;
    private final MembershipService membershipService;

    @Data
    public static class StartRequest {
        private String model;
    }

    @Data
    public static class PairRequest {
        private String code;
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

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}