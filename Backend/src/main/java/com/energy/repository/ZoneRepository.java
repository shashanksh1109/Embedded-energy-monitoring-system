package com.energy.repository;

import com.energy.model.Zone;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

/**
 * ZoneRepository - database access for the zones table
 *
 * Extends JpaRepository<Zone, UUID> which means:
 *   - Zone     = the entity this repository manages
 *   - UUID     = the type of the primary key
 *
 * FREE methods from JpaRepository (no code needed):
 *   findAll()              → SELECT * FROM zones
 *   findById(UUID id)      → SELECT * FROM zones WHERE id = ?
 *   save(Zone zone)        → INSERT or UPDATE
 *   deleteById(UUID id)    → DELETE FROM zones WHERE id = ?
 *   count()                → SELECT COUNT(*) FROM zones
 *   existsById(UUID id)    → SELECT 1 FROM zones WHERE id = ?
 */
@Repository
public interface ZoneRepository extends JpaRepository<Zone, UUID> {

    /**
     * Find a zone by its name e.g. "Zone_A"
     *
     * Spring reads the method name:
     *   findBy  → WHERE clause
     *   Name    → the 'name' field on Zone entity
     *
     * Generated SQL:
     *   SELECT * FROM zones WHERE name = ?
     *
     * Returns Optional<Zone> because the zone might not exist.
     * Optional is Java's way of saying "this might be null, handle it safely"
     * instead of returning null directly and risking NullPointerException.
     *
     * Usage:
     *   Optional<Zone> zone = zoneRepository.findByName("Zone_A");
     *   zone.isPresent()       → true if found
     *   zone.get()             → the Zone object
     *   zone.orElseThrow(...)  → get it or throw an exception
     */
    Optional<Zone> findByName(String name);

    /**
     * Check if a zone with this name already exists.
     *
     * Generated SQL:
     *   SELECT COUNT(*) > 0 FROM zones WHERE name = ?
     *
     * Returns boolean directly — no Optional needed.
     * Used before inserting a new zone to avoid duplicates.
     */
    boolean existsByName(String name);

}