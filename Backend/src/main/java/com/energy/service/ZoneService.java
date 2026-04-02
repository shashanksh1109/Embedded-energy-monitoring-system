package com.energy.service;

import com.energy.dto.ZoneResponse;
import com.energy.model.Zone;
import com.energy.repository.ZoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ZoneService {

    private final ZoneRepository zoneRepository;

    /**
     * Get all zones.
     *
     * @Transactional(readOnly = true)
     * Wraps this method in a database transaction.
     * readOnly = true tells the database this query will not
     * modify any data — the DB can optimize reads accordingly.
     * Always use readOnly = true on methods that only fetch data.
     */
    @Transactional(readOnly = true)
    public List<ZoneResponse> getAllZones() {
        return zoneRepository.findAll()       // List<Zone> from DB
            .stream()                          // turn list into a stream
            .map(ZoneResponse::from)           // convert each Zone → ZoneResponse
            .collect(Collectors.toList());     // gather back into a List
    }

    /**
     * Get one zone by name.
     *
     * orElseThrow() — if the zone doesn't exist, throw a clear
     * exception with a meaningful message instead of returning null.
     * The controller will catch this and return HTTP 404.
     */
    @Transactional(readOnly = true)
    public ZoneResponse getZoneByName(String name) {
        return zoneRepository.findByName(name)
            .map(ZoneResponse::from)
            .orElseThrow(() -> new RuntimeException("Zone not found: " + name));
    }

    /**
     * Internal helper used by other services.
     * Returns the raw Zone entity (not a DTO) because other
     * services need the entity to build their own responses.
     *
     * Not exposed as an API endpoint — only used internally.
     */
    @Transactional(readOnly = true)
    public Zone getZoneEntityByName(String name) {
        return zoneRepository.findByName(name)
            .orElseThrow(() -> new RuntimeException("Zone not found: " + name));
    }

}