package com.energy.service;

import com.energy.dto.DeviceResponse;
import com.energy.model.Device;
import com.energy.model.Zone;
import com.energy.repository.DeviceRepository;
import com.energy.repository.ZoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * DeviceService - business logic for devices
 */
@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final ZoneRepository zoneRepository;

    /** Thrown when a device or zone isn't found in the current organization. */
    public static class NotFoundException extends RuntimeException {
        public NotFoundException(String what) {
            super(what + " not found");
        }
    }

    @Transactional(readOnly = true)
    public List<DeviceResponse> getAllDevices() {
        return deviceRepository.findAll()
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DeviceResponse> getDevicesByZone(String zoneName) {
        return deviceRepository.findByZoneName(zoneName)
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    /** Only devices whose status is ACTIVE. */
    @Transactional(readOnly = true)
    public List<DeviceResponse> getActiveDevicesByZone(String zoneName) {
        return deviceRepository.findByZoneNameAndStatus(zoneName, Device.Status.ACTIVE)
            .stream()
            .map(DeviceResponse::from)
            .collect(Collectors.toList());
    }

    /** Look up a device by the name it sends, e.g. "TEMP_A". */
    @Transactional(readOnly = true)
    public DeviceResponse getDeviceByThingName(String thingName) {
        return deviceRepository.findByThingName(thingName)
            .map(DeviceResponse::from)
            .orElseThrow(() -> new RuntimeException("Device not found: " + thingName));
    }

    /**
     * Place a device in a zone (or take it out with zoneId = null).
     * Row-level security: only the current organization's devices and zones
     * can be found, so a device can never be moved into someone else's zone.
     * Once a device has a zone, the gateway starts accepting its readings.
     */
    @Transactional
    public DeviceResponse assignZone(UUID deviceId, UUID zoneId) {
        Device device = deviceRepository.findById(deviceId)
            .orElseThrow(() -> new NotFoundException("Device"));
        if ("HUB".equals(device.getDeviceType())) {
            throw new IllegalArgumentException("A hub itself is not placed in a zone; place its sensors");
        }
        Zone zone = null;
        if (zoneId != null) {
            zone = zoneRepository.findById(zoneId).orElseThrow(() -> new NotFoundException("Zone"));
        }
        device.setZone(zone);
        return DeviceResponse.from(deviceRepository.saveAndFlush(device));
    }
}