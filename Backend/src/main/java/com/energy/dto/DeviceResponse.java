package com.energy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * JSON sent to the frontend for one device.
 *
 * deviceId keeps its old name (it now carries the thing name, e.g. "TEMP_A").
 * useHardware/isActive/description are replaced by status, displayName,
 * lastSeenAt and a computed "online" flag.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DeviceResponse {

    /** A device counts as online if it reported within this many seconds. */
    public static final long ONLINE_WINDOW_SECONDS = 120;

    private UUID id;
    private String deviceId;
    private String displayName;
    private String deviceType;
    private String status;            // PENDING, ACTIVE or DISABLED
    private String zoneName;          // null if not placed in a zone yet
    private OffsetDateTime lastSeenAt;
    private Boolean online;
    private String firmwareVersion;
    private OffsetDateTime createdAt;

    public static DeviceResponse from(com.energy.model.Device device) {
        OffsetDateTime lastSeen = device.getLastSeenAt();
        boolean online = lastSeen != null
            && lastSeen.isAfter(OffsetDateTime.now().minusSeconds(ONLINE_WINDOW_SECONDS));

        return DeviceResponse.builder()
            .id(device.getId())
            .deviceId(device.getThingName())
            .displayName(device.getDisplayName())
            .deviceType(device.getDeviceType())
            .status(device.getStatus().name())
            .zoneName(device.getZone() == null ? null : device.getZone().getName())
            .lastSeenAt(lastSeen)
            .online(online)
            .firmwareVersion(device.getFirmwareVersion())
            .createdAt(device.getCreatedAt())
            .build();
    }
}