package com.energy.service;

import com.energy.security.TenantContext;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

/**
 * MembershipService - what is the current user allowed to do in the
 * current organization?
 *
 * Roles (memberships.role):
 *   OWNER  - everything, including managing the organization
 *   ADMIN  - manage zones and devices
 *   VIEWER - read only
 */
@Service
@RequiredArgsConstructor
public class MembershipService {

    private final JdbcTemplate jdbc;

    /** The user's role in the current organization, or null if not a member. */
    public String currentRole(Principal principal) {
        if (principal == null) {
            return null;
        }
        UUID userId;
        try {
            userId = UUID.fromString(principal.getName());
        } catch (IllegalArgumentException e) {
            // The built-in "admin" login is not a Cognito user and has no
            // membership row; it is treated as an administrator.
            return "ADMIN";
        }
        List<String> roles = jdbc.query(
            "SELECT role FROM memberships WHERE user_id = ? AND org_id = ?",
            (rs, rowNum) -> rs.getString(1),
            userId, TenantContext.get());
        return roles.isEmpty() ? null : roles.get(0);
    }

    /** True if the user may change zones and devices (OWNER or ADMIN). */
    public boolean canManage(Principal principal) {
        String role = currentRole(principal);
        return "OWNER".equals(role) || "ADMIN".equals(role);
    }
}