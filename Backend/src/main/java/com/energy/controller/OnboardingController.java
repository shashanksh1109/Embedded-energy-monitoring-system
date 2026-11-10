package com.energy.controller;

import com.energy.security.CognitoTokenVerifier;
import com.energy.service.OnboardingService;
import com.energy.service.OnboardingService.AlreadyOnboardedException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;
import java.util.UUID;

/**
 * OnboardingController - self-service sign-up, step 2.
 *
 *   GET  /api/onboarding/status  -> {"hasOrganization": true|false}
 *   POST /api/onboarding         -> {"organizationName": "...", "displayName": "..."}
 *
 * Both require a valid Cognito access token.
 */
@RestController
@RequestMapping("/api/onboarding")
@RequiredArgsConstructor
public class OnboardingController {

    private final OnboardingService onboarding;
    private final ObjectProvider<CognitoTokenVerifier> cognitoProvider;

    @Data
    public static class OnboardingRequest {
        private String organizationName;
        private String displayName;
    }

    @GetMapping("/status")
    public ResponseEntity<?> status(Principal principal) {
        String sub = cognitoSub(principal);
        if (sub == null) {
            return error(HttpStatus.BAD_REQUEST, "Only Cognito users can be onboarded");
        }
        return ResponseEntity.ok(Map.of("hasOrganization", onboarding.hasMembership(sub)));
    }

    @PostMapping
    public ResponseEntity<?> onboard(@RequestBody OnboardingRequest body,
                                     Principal principal,
                                     HttpServletRequest request) {
        String sub = cognitoSub(principal);
        if (sub == null) {
            return error(HttpStatus.BAD_REQUEST, "Only Cognito users can be onboarded");
        }

        String orgName = body.getOrganizationName() == null ? "" : body.getOrganizationName().trim();
        if (orgName.isEmpty() || orgName.length() > 120) {
            return error(HttpStatus.BAD_REQUEST, "Organization name must be 1-120 characters");
        }
        String displayName = body.getDisplayName() == null ? null : body.getDisplayName().trim();
        if (displayName != null && displayName.length() > 120) {
            return error(HttpStatus.BAD_REQUEST, "Display name must be at most 120 characters");
        }

        // The email comes from Cognito, never from the request body
        String accessToken = request.getHeader("Authorization").substring(7);
        String email = cognitoProvider.getObject().fetchEmail(accessToken);
        if (email == null) {
            return error(HttpStatus.BAD_GATEWAY, "Could not read your account from Cognito");
        }

        try {
            UUID orgId = onboarding.createOrganization(sub, email, displayName, orgName);
            return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("orgId", orgId, "organizationName", orgName));
        } catch (AlreadyOnboardedException e) {
            return error(HttpStatus.CONFLICT, e.getMessage());
        }
    }

    /** For Cognito users the principal is their Cognito ID (a UUID). */
    private String cognitoSub(Principal principal) {
        if (principal == null || cognitoProvider.getIfAvailable() == null) {
            return null;
        }
        try {
            return UUID.fromString(principal.getName()).toString();
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}