package com.energy.controller;

import com.energy.dto.ZoneResponse;
import com.energy.service.ZoneService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/zones")
@RequiredArgsConstructor
public class ZoneController {

    private final ZoneService zoneService;

    @GetMapping
    public ResponseEntity<List<ZoneResponse>> getAllZones() {
        return ResponseEntity.ok(zoneService.getAllZones());
    }

    @GetMapping("/{name}")
    public ResponseEntity<ZoneResponse> getZoneByName(@PathVariable String name) {
        return ResponseEntity.ok(zoneService.getZoneByName(name));
    }
}
