package com.energy.service;

import com.energy.dto.DeviceResponse;
import com.energy.model.Device;
import com.energy.repository.DeviceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * DeviceService - business logic for devices
 */
@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;

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
}