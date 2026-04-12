package com.energy.service;

import com.energy.dto.ZoneResponse;
import com.energy.model.Zone;
import com.energy.repository.ZoneRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ZoneServiceTest {

    @Mock
    private ZoneRepository zoneRepository;

    @InjectMocks
    private ZoneService zoneService;

    private Zone zoneA;
    private Zone zoneB;

    @BeforeEach
    void setUp() {
        zoneA = Zone.builder()
            .id(UUID.randomUUID())
            .name("Zone_A")
            .description("Conference Room")
            .capacity(20)
            .build();

        zoneB = Zone.builder()
            .id(UUID.randomUUID())
            .name("Zone_B")
            .description("Executive Office")
            .capacity(10)
            .build();
    }

    @Test
    void getAllZones_shouldReturnAllZones() {
        when(zoneRepository.findAll()).thenReturn(List.of(zoneA, zoneB));

        List<ZoneResponse> result = zoneService.getAllZones();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getName()).isEqualTo("Zone_A");
        assertThat(result.get(1).getName()).isEqualTo("Zone_B");
    }

    @Test
    void getAllZones_whenEmpty_shouldReturnEmptyList() {
        when(zoneRepository.findAll()).thenReturn(List.of());

        List<ZoneResponse> result = zoneService.getAllZones();

        assertThat(result).isEmpty();
    }

    @Test
    void getZoneByName_whenExists_shouldReturnZone() {
        when(zoneRepository.findByName("Zone_A")).thenReturn(Optional.of(zoneA));

        ZoneResponse result = zoneService.getZoneByName("Zone_A");

        assertThat(result).isNotNull();
        assertThat(result.getName()).isEqualTo("Zone_A");
        assertThat(result.getCapacity()).isEqualTo(20);
    }

    @Test
    void getZoneByName_whenNotExists_shouldThrowException() {
        when(zoneRepository.findByName("Zone_X")).thenReturn(Optional.empty());

        // Service should throw an exception when zone not found
        assertThatThrownBy(() -> zoneService.getZoneByName("Zone_X"))
            .isInstanceOf(RuntimeException.class);
    }

    @Test
    void getAllZones_shouldCallRepositoryOnce() {
        when(zoneRepository.findAll()).thenReturn(List.of(zoneA));

        zoneService.getAllZones();

        verify(zoneRepository, times(1)).findAll();
    }
}
