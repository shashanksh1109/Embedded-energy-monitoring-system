package com.energy.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * AuthController - login endpoint
 *
 * POST /api/auth/login  {"username": "...", "password": "..."}
 *
 * For now there is one built-in user (admin) who belongs to ONE organization,
 * configured by app.tenant.default-org-id (the demo organization from the
 * seed data). That organization's ID is put into the token, and every later
 * request is limited to it. When Cognito replaces this login, each user's
 * organization will come from the memberships table instead.
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    /** Organization of the built-in admin user (the demo org from seed data). */
    @Value("${app.tenant.default-org-id:00000000-0000-0000-0000-000000000001}")
    private UUID defaultOrgId;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    request.getUsername(),
                    request.getPassword()
                )
            );

            String token = jwtUtil.generateToken(request.getUsername(), defaultOrgId);

            return ResponseEntity.ok(new LoginResponse(
                token,
                request.getUsername(),
                defaultOrgId,
                86400000L
            ));

        } catch (AuthenticationException e) {
            return ResponseEntity
                .status(401)
                .body(new ErrorResponse("Invalid username or password"));
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LoginResponse {
        private String token;
        private String username;
        private UUID orgId;
        private Long expiresIn;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ErrorResponse {
        private String error;
    }
}