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
     * Find a device by its string identifier e.g. "TEMP_A"
     *
     * Generated SQL:
     *   SELECT * FROM devices WHERE device_id = ?
     *
     * Returns Optional because the device might not exist.
     * Used when a packet arrives at the gateway and we need
     * to verify the device is registered.
     */
    Optional<Device> findByDeviceId(String deviceId);

    /**
     * Find all devices belonging to a specific zone.
     *
     * Spring reads:
     *   findBy  → WHERE clause
     *   Zone    → follow the zone relationship
     *   Name    → on the Zone object, use its name field
     *
     * Generated SQL:
     *   SELECT d.* FROM devices d
     *   JOIN zones z ON d.zone_id = z.id
     *   WHERE z.name = ?
     *
     * Returns List because a zone has multiple devices.
     * List is never null — if nothing found it returns empty list [].
     */
    List<Device> findByZoneName(String zoneName);

    /**
     * Find all active devices in a zone.
     *
     * Spring reads three conditions chained together:
     *   Zone_Name  → JOIN zones WHERE z.name = ?
     *   And        → AND
     *   IsActive   → AND d.is_active = ?
     *
     * Generated SQL:
     *   SELECT d.* FROM devices d
     *   JOIN zones z ON d.zone_id = z.id
     *   WHERE z.name = ?
     *   AND d.is_active = true
     *
     * Used by the dashboard to show only currently active sensors.
     */
    List<Device> findByZoneNameAndIsActive(String zoneName, Boolean isActive);

    /**
     * Check if a device with this ID already exists.
     *
     * Generated SQL:
     *   SELECT COUNT(*) > 0 FROM devices WHERE device_id = ?
     *
     * Used before registering a new device to avoid duplicates.
     */
    boolean existsByDeviceId(String deviceId);

}