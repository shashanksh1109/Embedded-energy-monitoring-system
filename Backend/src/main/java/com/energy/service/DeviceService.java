package com.energy.service;

import com.energy.dto.DeviceResponse;
import com.energy.repository.DeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;

    /**
     * Get all devices across all zones.
     * Used by dashboard overview — show every sensor in the system.
     */
    @Transactional(readOnly = true)
    public List<DeviceResponse> getAllDevices() {
        return deviceRepository.findAll()
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get all devices in a specific zone.
     * Used by zone detail page — "what sensors are in Zone_A?"
     */
    @Transactional(readOnly = true)
    public List<DeviceResponse> getDevicesByZone(String zoneName) {
        return deviceRepository.findByZoneName(zoneName)
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get only active devices in a zone.
     * Used by live dashboard — only show sensors currently sending data.
     *
     * Notice: we pass true as the second argument — hardcoded here
     * in the service because "active" is the only meaningful filter.
     * The controller doesn't need to know the DB column name.
     */
    @Transactional(readOnly = true)
    public List<DeviceResponse> getActiveDevicesByZone(String zoneName) {
        return deviceRepository.findByZoneNameAndIsActive(zoneName, true)
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    /**
     * Get a single device by its string ID e.g. "TEMP_A"
     *
     * Returns DeviceResponse or throws if not found.
     */
    @Transactional(readOnly = true)
    public DeviceResponse getDeviceByDeviceId(String deviceId) {
        return deviceRepository.findByDeviceId(deviceId)
            .map(DeviceResponse::from)
            .orElseThrow(() -> new RuntimeException("Device not found: " + deviceId));
    }

}