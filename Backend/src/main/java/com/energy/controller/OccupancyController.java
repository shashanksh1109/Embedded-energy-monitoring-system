package com.energy.controller;

import com.energy.dto.OccupancyResponse;
import com.energy.service.OccupancyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/occupancy")
@RequiredArgsConstructor
public class OccupancyController {

    private final OccupancyService occupancyService;

    @GetMapping("/{zone}")
    public ResponseEntity<List<OccupancyResponse>> getByZone(@PathVariable String zone) {
        return ResponseEntity.ok(occupancyService.getReadingsForZone(zone));
    }

    @GetMapping("/{zone}/latest")
    public ResponseEntity<OccupancyResponse> getLatestByZone(@PathVariable String zone) {
        return ResponseEntity.ok(occupancyService.getLatestForZone(zone));
    }
}
