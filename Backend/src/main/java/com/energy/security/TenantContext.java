package com.energy.security;

import java.util.UUID;

/**
 * TenantContext - remembers which organization the CURRENT request belongs to.
 *
 * JwtFilter sets it from the token at the start of each request and clears it
 * at the end. The database layer (TenantDataSourceConfig) reads it and tells
 * PostgreSQL, so row-level security only returns that organization's rows.
 *
 * It is a ThreadLocal: each request runs on its own thread, so two users'
 * requests can never see each other's value.
 */
public final class TenantContext {

    /**
     * Used when a request has no organization (not logged in, or a public
     * endpoint). It matches no organization, so row-level security returns
     * nothing instead of everything - the same "fail closed" rule as Step 24.
     */
    public static final UUID NO_TENANT = new UUID(0L, 0L);

    private static final ThreadLocal<UUID> CURRENT = new ThreadLocal<>();

    private TenantContext() {
    }

    public static void set(UUID orgId) {
        CURRENT.set(orgId);
    }

    /** The current organization, or NO_TENANT if none was set. */
    public static UUID get() {
        UUID orgId = CURRENT.get();
        return orgId != null ? orgId : NO_TENANT;
    }

    /** Must be called at the end of every request (threads are reused). */
    public static void clear() {
        CURRENT.remove();
    }
}