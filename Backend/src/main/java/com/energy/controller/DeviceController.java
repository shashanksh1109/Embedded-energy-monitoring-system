package com.energy.controller;

import com.energy.dto.DeviceResponse;
import com.energy.service.DeviceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
public class DeviceController {

    private final DeviceService deviceService;

    @GetMapping
    public ResponseEntity<List<DeviceResponse>> getAllDevices() {
        return ResponseEntity.ok(deviceService.getAllDevices());
    }

    @GetMapping("/zone/{zone}")
    public ResponseEntity<List<DeviceResponse>> getByZone(@PathVariable String zone) {
        return ResponseEntity.ok(deviceService.getDevicesByZone(zone));
    }
}
