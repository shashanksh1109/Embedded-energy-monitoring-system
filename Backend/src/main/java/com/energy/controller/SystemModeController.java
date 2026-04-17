package com.energy.controller;

import com.energy.model.SystemMode;
import com.energy.service.SystemModeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/mode")
public class SystemModeController {

    @Autowired
    private SystemModeService service;

    // GET /api/mode — get current mode + sensor status
    @GetMapping
    public ResponseEntity<Map<String, Object>> getMode() {
        SystemMode mode = service.getCurrentMode();
        Map<String, Object> response = new HashMap<>();
        response.put("mode", mode.getMode());
        response.put("updatedAt", mode.getUpdatedAt());
        response.put("sensorRunning", service.isSensorRunning());
        return ResponseEntity.ok(response);
    }

    // POST /api/mode/simulation — switch to simulation
    @PostMapping("/simulation")
    public ResponseEntity<Map<String, Object>> setSimulation() {
        SystemMode mode = service.setSimulationMode();
        Map<String, Object> response = new HashMap<>();
        response.put("mode", mode.getMode());
        response.put("message", "Switched to simulation mode. Sensor service starting...");
        response.put("updatedAt", mode.getUpdatedAt());
        return ResponseEntity.ok(response);
    }

    // POST /api/mode/hardware — switch to hardware
    @PostMapping("/hardware")
    public ResponseEntity<Map<String, Object>> setHardware() {
        SystemMode mode = service.setHardwareMode();
        Map<String, Object> response = new HashMap<>();
        response.put("mode", mode.getMode());
        response.put("message", "Switched to hardware mode. Connect PICsimLAB to begin.");
        response.put("updatedAt", mode.getUpdatedAt());
        return ResponseEntity.ok(response);
    }
}
