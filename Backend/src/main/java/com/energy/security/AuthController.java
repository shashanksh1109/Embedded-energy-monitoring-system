package com.energy.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

/**
 * AuthController - handles login and token generation
 *
 * This is the ONLY public endpoint in the system.
 * No JWT token required to call POST /api/auth/login.
 * All other endpoints require a valid token.
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    /**
     * POST /api/auth/login
     *
     * Request body (JSON):
     * {
     *   "username": "admin",
     *   "password": "energy123"
     * }
     *
     * Success response (HTTP 200):
     * {
     *   "token": "eyJhbGciOiJIUzI1NiJ9...",
     *   "username": "admin",
     *   "expiresIn": 86400000
     * }
     *
     * Failure response (HTTP 401):
     * {
     *   "error": "Invalid username or password"
     * }
     *
     * @RequestBody = Spring reads the JSON body of the request
     * and converts it into a LoginRequest object automatically.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // ─────────────────────────────────────────────
            // STEP 1: Verify username and password
            //
            // AuthenticationManager is Spring Security's
            // central authentication processor.
            //
            // authenticate() does three things:
            //   1. Finds the user by username
            //   2. Checks the password matches
            //   3. Throws AuthenticationException if either fails
            //
            // UsernamePasswordAuthenticationToken wraps the
            // credentials into a format Spring Security understands.
            // ─────────────────────────────────────────────
            authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    request.getUsername(),
                    request.getPassword()
                )
            );

            // ─────────────────────────────────────────────
            // STEP 2: Generate JWT token
            //
            // If we reach this line, authentication succeeded.
            // Generate a token for this username.
            // ─────────────────────────────────────────────
            String token = jwtUtil.generateToken(request.getUsername());

            // ─────────────────────────────────────────────
            // STEP 3: Return token to caller
            //
            // The caller stores this token and includes it
            // in every subsequent request header:
            //   Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
            // ─────────────────────────────────────────────
            return ResponseEntity.ok(new LoginResponse(
                token,
                request.getUsername(),
                86400000L
            ));

        } catch (AuthenticationException e) {
            // Authentication failed — wrong username or password
            // Return 401 Unauthorized with a clear message
            return ResponseEntity
                .status(401)
                .body(new ErrorResponse("Invalid username or password"));
        }
    }

    // ─────────────────────────────────────────────────────
    // INNER CLASSES — request and response shapes
    //
    // These are small, self-contained data classes used only
    // by this controller. Keeping them here as inner classes
    // avoids creating separate files for tiny DTOs.
    // ─────────────────────────────────────────────────────

    /**
     * LoginRequest — shape of the incoming JSON body
     *
     * Spring reads the request JSON and maps it here:
     * { "username": "admin", "password": "energy123" }
     *   → LoginRequest { username="admin", password="energy123" }
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginRequest {
        private String username;
        private String password;
    }

    /**
     * LoginResponse — shape of the success response
     *
     * Sent back to the caller on successful login.
     * { "token": "eyJ...", "username": "admin", "expiresIn": 86400000 }
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginResponse {
        private String token;
        private String username;
        private Long expiresIn;
    }

    /**
     * ErrorResponse — shape of the error response
     *
     * Sent back when login fails.
     * { "error": "Invalid username or password" }
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ErrorResponse {
        private String error;
    }

}