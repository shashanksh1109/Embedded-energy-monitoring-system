package com.energy.service;

import com.energy.dto.ZoneResponse;
import com.energy.model.Building;
import com.energy.model.Zone;
import com.energy.repository.BuildingRepository;
import com.energy.repository.ZoneRepository;
import com.energy.security.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * ZoneService - business logic for zones.
 * Row-level security already limits every query to the current organization.
 */
@Service
@RequiredArgsConstructor
public class ZoneService {

    /** Thrown when the organization has no building to put the zone in. */
    public static class NoBuildingException extends RuntimeException {
        public NoBuildingException() {
            super("Your organization has no building yet");
        }
    }

    private final ZoneRepository zoneRepository;
    private final BuildingRepository buildingRepository;

    @Transactional(readOnly = true)
    public List<ZoneResponse> getAllZones() {
        return zoneRepository.findAll()
            .stream()
            .map(ZoneResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ZoneResponse getZoneByName(String name) {
        return zoneRepository.findByName(name)
            .map(ZoneResponse::from)
            .orElseThrow(() -> new RuntimeException("Zone not found: " + name));
    }

    /**
     * Create a zone in the organization's first building.
     * org_id comes from the request's organization (TenantContext), never
     * from the caller; row-level security's WITH CHECK rejects anything else.
     */
    @Transactional
    public ZoneResponse createZone(String name, String description, int capacity) {
        List<Building> buildings = buildingRepository.findAllByOrderByCreatedAtAsc();
        if (buildings.isEmpty()) {
            throw new NoBuildingException();
        }

        Zone zone = Zone.builder()
            .orgId(TenantContext.get())
            .building(buildings.get(0))
            .name(name)
            .description(description)
            .capacity(capacity)
            .build();

        // saveAndFlush: run the INSERT now, so a duplicate name fails here
        // (and can be reported as 409) instead of at commit time
        return ZoneResponse.from(zoneRepository.saveAndFlush(zone));
    }
}