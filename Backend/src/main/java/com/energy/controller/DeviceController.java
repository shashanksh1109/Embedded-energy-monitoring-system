package com.energy.controller;

import com.energy.dto.DeviceResponse;
import com.energy.service.DeviceRegistrationService;
import com.energy.service.DeviceRegistrationService.ClaimResult;
import com.energy.service.DeviceRegistrationService.Registration;
import com.energy.service.DeviceRegistrationService.ZoneNotFoundException;
import com.energy.service.DeviceService;
import com.energy.service.MembershipService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceController {

    private static final Set<String> DEVICE_TYPES = Set.of("TEMP", "OCCUPANCY", "HVAC", "POWER", "MULTI");

    private final DeviceService deviceService;
    private final DeviceRegistrationService registrationService;
    private final MembershipService membershipService;

    @Data
    public static class RegisterRequest {
        private UUID zoneId;
        private String deviceType;
        private String displayName;
    }

    @Data
    public static class ClaimRequest {
        private String code;
    }

    @GetMapping
    public ResponseEntity<List<DeviceResponse>> getAllDevices() {
        return ResponseEntity.ok(deviceService.getAllDevices());
    }

    @GetMapping("/zone/{zone}")
    public ResponseEntity<List<DeviceResponse>> getByZone(@PathVariable String zone) {
        return ResponseEntity.ok(deviceService.getDevicesByZone(zone));
    }

    /**
     * Add a device to one of the organization's zones (OWNER or ADMIN).
     * Returns the device (PENDING) and a one-time claim code.
     */
    @PostMapping
    public ResponseEntity<?> register(@RequestBody RegisterRequest body, Principal principal) {
        if (!membershipService.canManage(principal)) {
            return error(HttpStatus.FORBIDDEN, "Only an owner or admin can add devices");
        }
        if (body.getZoneId() == null) {
            return error(HttpStatus.BAD_REQUEST, "zoneId is required");
        }
        String type = body.getDeviceType() == null ? "" : body.getDeviceType().trim().toUpperCase();
        if (!DEVICE_TYPES.contains(type)) {
            return error(HttpStatus.BAD_REQUEST, "deviceType must be one of " + DEVICE_TYPES);
        }
        String displayName = body.getDisplayName() == null ? null : body.getDisplayName().trim();
        if (displayName != null && displayName.length() > 120) {
            return error(HttpStatus.BAD_REQUEST, "Display name must be at most 120 characters");
        }

        try {
            Registration r = registrationService.register(body.getZoneId(), type, displayName);
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "device", r.device(),
                "claimCode", r.claimCode(),
                "claimExpiresAt", r.claimExpiresAt()
            ));
        } catch (ZoneNotFoundException e) {
            return error(HttpStatus.NOT_FOUND, e.getMessage());
        } catch (DataIntegrityViolationException e) {
            return error(HttpStatus.CONFLICT, "Could not create the device, please try again");
        }
    }

    /**
     * Claim a device with its one-time code. PUBLIC (no login): the device
     * itself calls this during setup. The code is the only proof needed.
     */
    @PostMapping("/claim")
    public ResponseEntity<?> claim(@RequestBody ClaimRequest body) {
        ClaimResult result = registrationService.claim(body.getCode());
        if (result == null) {
            return error(HttpStatus.NOT_FOUND, "Invalid, used or expired claim code");
        }
        return ResponseEntity.ok(Map.of(
            "thingName", result.thingName(),
            "deviceType", result.deviceType(),
            "zoneName", result.zoneName()
        ));
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}