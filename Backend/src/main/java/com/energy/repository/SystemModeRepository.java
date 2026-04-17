package com.energy.repository;

import com.energy.model.SystemMode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SystemModeRepository extends JpaRepository<SystemMode, Integer> {}
