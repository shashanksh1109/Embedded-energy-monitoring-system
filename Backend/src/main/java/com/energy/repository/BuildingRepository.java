package com.energy.repository;

import com.energy.model.Building;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * BuildingRepository - database access for the buildings table.
 * Row-level security limits every query to the current organization.
 */
@Repository
public interface BuildingRepository extends JpaRepository<Building, UUID> {

    /** The organization's buildings, oldest first. */
    List<Building> findAllByOrderByCreatedAtAsc();
}