package com.energy.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

/**
 * JwtUtil - generates and validates JWT tokens
 *
 * A token now carries two facts about the user:
 *   sub = the username             (who you are)
 *   org = the organization's UUID  (whose data you may see)
 *
 * Both are inside the signed payload, so nobody can change "org" to another
 * customer's ID without breaking the signature.
 */
@Component
public class JwtUtil {

    /** Name of the claim that holds the organization ID. */
    public static final String ORG_CLAIM = "org";

    @Value("${jwt.secret}")
    private String secretString;

    @Value("${jwt.expiration.ms}")
    private long expirationMs;  // 86400000 = 24 hours in milliseconds

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secretString.getBytes());
    }

    /** Token for a user who belongs to an organization. */
    public String generateToken(String username, UUID orgId) {
        JwtBuilder builder = Jwts.builder()
            .subject(username)
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expirationMs));
        if (orgId != null) {
            builder.claim(ORG_CLAIM, orgId.toString());
        }
        return builder.signWith(getSigningKey()).compact();
    }

    /** Token without an organization (sees no tenant data). */
    public String generateToken(String username) {
        return generateToken(username, null);
    }

    public String extractUsername(String token) {
        return getClaims(token).getSubject();
    }

    /** The organization ID inside the token, or null if it has none. */
    public UUID extractOrgId(String token) {
        String org = getClaims(token).get(ORG_CLAIM, String.class);
        return org == null ? null : UUID.fromString(org);
    }

    public boolean isTokenValid(String token, String username) {
        try {
            String extractedUsername = extractUsername(token);
            return extractedUsername.equals(username) && !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        return getClaims(token).getExpiration().before(new Date());
    }

    /** Verify the signature and return the payload (throws if invalid). */
    private Claims getClaims(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }
}