package com.energy.repository;

import com.energy.model.HvacState;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * HvacStateRepository - database access for the hvac_state table
 */
@Repository
public interface HvacStateRepository extends JpaRepository<HvacState, UUID> {

    List<HvacState> findByZoneNameOrderByRecordedAtDesc(String zoneName);

    List<HvacState> findByZoneNameAndRecordedAtBetweenOrderByRecordedAtDesc(
        String zoneName,
        OffsetDateTime from,
        OffsetDateTime to
    );

    Optional<HvacState> findTop1ByZoneNameOrderByRecordedAtDesc(String zoneName);

    List<HvacState> findTop20ByZoneNameOrderByRecordedAtDesc(String zoneName);

    /**
     * How many HVAC records in the range were heating.
     * COUNT runs in the database and returns one number, instead of
     * loading every matching row into memory just to call .size().
     */
    @Query("SELECT COUNT(h) FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to " +
           "AND h.heaterPct > 0")
    long countHeatingStates(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /** How many HVAC records in the range were cooling. */
    @Query("SELECT COUNT(h) FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to " +
           "AND h.coolerPct > 0")
    long countCoolingStates(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );

    /** Average heater and cooler output: [0] = avg heater %, [1] = avg cooler %. */
    @Query("SELECT AVG(h.heaterPct), AVG(h.coolerPct) " +
           "FROM HvacState h " +
           "WHERE h.zone.name = :zoneName " +
           "AND h.recordedAt BETWEEN :from AND :to")
    Optional<Object[]> findAverageUsage(
        @Param("zoneName") String zoneName,
        @Param("from") OffsetDateTime from,
        @Param("to") OffsetDateTime to
    );
}