package com.energy.controller;

import com.energy.dto.ZoneResponse;
import com.energy.service.MembershipService;
import com.energy.service.ZoneService;
import com.energy.service.ZoneService.NoBuildingException;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/zones")
@RequiredArgsConstructor
public class ZoneController {

    private final ZoneService zoneService;
    private final MembershipService membershipService;

    @Data
    public static class CreateZoneRequest {
        private String name;
        private String description;
        private Integer capacity;
    }

    @GetMapping
    public ResponseEntity<List<ZoneResponse>> getAllZones() {
        return ResponseEntity.ok(zoneService.getAllZones());
    }

    @GetMapping("/{name}")
    public ResponseEntity<ZoneResponse> getZoneByName(@PathVariable String name) {
        return ResponseEntity.ok(zoneService.getZoneByName(name));
    }

    /** Create a zone in the current organization (OWNER or ADMIN only). */
    @PostMapping
    public ResponseEntity<?> createZone(@RequestBody CreateZoneRequest body, Principal principal) {
        if (!membershipService.canManage(principal)) {
            return error(HttpStatus.FORBIDDEN, "Only an owner or admin can add zones");
        }

        String name = body.getName() == null ? "" : body.getName().trim();
        if (name.isEmpty() || name.length() > 64) {
            return error(HttpStatus.BAD_REQUEST, "Zone name must be 1-64 characters");
        }
        String description = body.getDescription() == null ? null : body.getDescription().trim();
        if (description != null && description.length() > 255) {
            return error(HttpStatus.BAD_REQUEST, "Description must be at most 255 characters");
        }
        int capacity = body.getCapacity() == null ? 0 : body.getCapacity();
        if (capacity < 0) {
            return error(HttpStatus.BAD_REQUEST, "Capacity cannot be negative");
        }

        try {
            ZoneResponse zone = zoneService.createZone(name, description, capacity);
            return ResponseEntity.status(HttpStatus.CREATED).body(zone);
        } catch (NoBuildingException e) {
            return error(HttpStatus.CONFLICT, e.getMessage());
        } catch (DataIntegrityViolationException e) {
            return error(HttpStatus.CONFLICT, "A zone with this name already exists");
        }
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}