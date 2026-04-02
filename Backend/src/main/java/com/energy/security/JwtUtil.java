package com.energy.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

/**
 * JwtUtil - generates and validates JWT tokens
 *
 * @Component = a Spring bean that doesn't fit
 * @Service, @Repository, or @Controller.
 * It's a utility class — Spring manages it as a bean
 * so it can be injected wherever needed.
 */
@Component
public class JwtUtil {

    /**
     * @Value("${jwt.secret}")
     *
     * Injects the value of jwt.secret from application.properties
     * directly into this field at startup.
     *
     * application.properties:
     *   jwt.secret=energy-monitoring-secret-key-...
     *
     * Spring reads that property and sets secretString to that value.
     * You never hardcode secrets in Java code — always in config.
     */
    @Value("${jwt.secret}")
    private String secretString;

    @Value("${jwt.expiration.ms}")
    private long expirationMs;  // 86400000 = 24 hours in milliseconds

    /**
     * Convert the secret string into a cryptographic key.
     *
     * HMAC-SHA256 requires a proper SecretKey object, not a plain string.
     * Keys.hmacShaKeyFor() converts the string bytes into a SecretKey.
     *
     * Called internally before signing or validating tokens.
     */
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secretString.getBytes());
    }

    /**
     * Generate a JWT token for a given username.
     *
     * Called when a user successfully logs in.
     * Returns a token string like:
     *   eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbiIs...
     *
     * Token contains:
     *   subject   = username
     *   issuedAt  = current time
     *   expiration = current time + 24 hours
     *   signature  = HMAC-SHA256 using secret key
     */
    public String generateToken(String username) {
        return Jwts.builder()
            .subject(username)                              // who this token is for
            .issuedAt(new Date())                           // when it was created
            .expiration(new Date(System.currentTimeMillis() + expirationMs)) // when it expires
            .signWith(getSigningKey())                      // sign with secret key
            .compact();                                     // build the string
    }

    /**
     * Extract the username from a token.
     *
     * Called by JwtFilter to find out who is making the request.
     * Parses the token, verifies the signature, returns the subject.
     */
    public String extractUsername(String token) {
        return getClaims(token).getSubject();
    }

    /**
     * Check if a token is valid.
     *
     * Valid means:
     *   1. Signature is correct (not tampered with)
     *   2. Token has not expired
     *   3. Username in token matches the expected username
     */
    public boolean isTokenValid(String token, String username) {
        try {
            String extractedUsername = extractUsername(token);
            return extractedUsername.equals(username) && !isTokenExpired(token);
        } catch (Exception e) {
            // Any parsing error means invalid token
            return false;
        }
    }

    /**
     * Check if a token has expired.
     *
     * Extracts the expiration date from the token
     * and compares it to the current time.
     */
    private boolean isTokenExpired(String token) {
        return getClaims(token).getExpiration().before(new Date());
    }

    /**
     * Parse the token and extract all claims.
     *
     * Claims are the payload of the JWT — subject, issuedAt,
     * expiration, and any custom fields.
     *
     * If the token is tampered with or the signature doesn't match,
     * this throws an exception — caught by isTokenValid().
     */
    private Claims getClaims(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())   // verify signature with secret key
            .build()
            .parseSignedClaims(token)      // parse and validate
            .getPayload();                 // return the claims
    }

}