package com.energy.service;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * OnboardingService - a new user creates their own organization.
 *
 * Runs as ONE transaction, so either everything is created or nothing is:
 *   1. the organization
 *   2. the user's app_users row (linked to their Cognito ID)
 *   3. an OWNER membership linking the two
 *   4. a first building, so the customer can start adding zones
 */
@Service
@RequiredArgsConstructor
public class OnboardingService {

    /** Thrown when the user already belongs to an organization. */
    public static class AlreadyOnboardedException extends RuntimeException {
        public AlreadyOnboardedException() {
            super("You already belong to an organization");
        }
    }

    private final JdbcTemplate jdbc;

    public boolean hasMembership(String userSub) {
        Integer count = jdbc.queryForObject(
            "SELECT count(*) FROM memberships WHERE user_id = ?::uuid",
            Integer.class, userSub);
        return count != null && count > 0;
    }

    @Transactional
    public UUID createOrganization(String userSub, String email, String displayName,
                                   String organizationName) {

        // Two quick clicks could send two requests at once. This lock makes the
        // second one wait for the first, then the re-check below stops it.
        jdbc.queryForObject("SELECT pg_advisory_xact_lock(hashtext(?))", Object.class, userSub);
        if (hasMembership(userSub)) {
            throw new AlreadyOnboardedException();
        }

        UUID orgId = jdbc.queryForObject(
            "INSERT INTO organizations (name) VALUES (?) RETURNING id",
            UUID.class, organizationName);

        jdbc.update(
            "INSERT INTO app_users (id, email, display_name) VALUES (?::uuid, ?, ?) " +
            "ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, display_name = EXCLUDED.display_name",
            userSub, email, displayName);

        jdbc.update(
            "INSERT INTO memberships (org_id, user_id, role) VALUES (?, ?::uuid, 'OWNER')",
            orgId, userSub);

        // buildings has row-level security: work as the NEW organization for the
        // rest of this transaction (true = setting ends when the transaction ends)
        jdbc.queryForObject(
            "SELECT set_config('app.current_org', ?, true)",
            String.class, orgId.toString());

        jdbc.update(
            "INSERT INTO buildings (org_id, name) VALUES (?, ?)",
            orgId, "Main building");

        return orgId;
    }
}