package com.energy.repository;

import com.energy.model.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * DeviceRepository - database access for the devices table
 */
@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {

    /**
     * Find a device by the name it sends in its packets, e.g. "TEMP_A".
     * SQL: SELECT * FROM devices WHERE thing_name = ?
     */
    Optional<Device> findByThingName(String thingName);

    /**
     * All devices placed in a zone.
     * SQL: SELECT d.* FROM devices d JOIN zones z ON d.zone_id = z.id WHERE z.name = ?
     */
    List<Device> findByZoneName(String zoneName);

    /**
     * Devices in a zone with a given status, e.g. only ACTIVE ones.
     * SQL: ... WHERE z.name = ? AND d.status = ?
     */
    List<Device> findByZoneNameAndStatus(String zoneName, Device.Status status);

    /**
     * Check whether a thing name is already registered (before adding a device).
     */
    boolean existsByThingName(String thingName);
}