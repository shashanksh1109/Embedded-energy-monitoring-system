package com.energy.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "system_mode")
public class SystemMode {

    @Id
    @Column(name = "id")
    private Integer id = 1;

    @Column(name = "mode", nullable = false)
    private String mode;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public SystemMode() {}

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
