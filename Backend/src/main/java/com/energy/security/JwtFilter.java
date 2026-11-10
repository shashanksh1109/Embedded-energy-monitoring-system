package com.energy.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

/**
 * JwtFilter - runs once for every HTTP request.
 *
 * Accepts two kinds of bearer tokens:
 *   1. our own tokens from POST /api/auth/login (built-in admin; the org is
 *      inside the token), and
 *   2. Cognito access tokens (real users; the org comes from memberships).
 *
 * Either way, a valid token marks the request as authenticated and puts the
 * user's organization into TenantContext, so every database query in this
 * request only sees that organization's rows.
 *
 * TenantContext is ALWAYS cleared at the end (finally), because server
 * threads are reused.
 */
@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    /**
     * ObjectProvider = "inject it if it exists". Some slim test contexts
     * don't create the Cognito verifier; the filter still works without it.
     */
    private final ObjectProvider<CognitoTokenVerifier> cognitoProvider;

    public JwtFilter(JwtUtil jwtUtil, ObjectProvider<CognitoTokenVerifier> cognitoProvider) {
        this.jwtUtil = jwtUtil;
        this.cognitoProvider = cognitoProvider;
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        try {
            authenticate(request);
            filterChain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private void authenticate(HttpServletRequest request) {
        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return;                                   // no token: SecurityConfig decides
        }
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
            return;                                   // already authenticated
        }

        String token = authHeader.substring(7);

        // 1. Our own token (built-in admin login)
        if (tryLocalToken(token, request)) {
            return;
        }

        // 2. Cognito access token
        CognitoTokenVerifier cognito = cognitoProvider.getIfAvailable();
        if (cognito != null) {
            Jwt jwt = cognito.verify(token);
            if (jwt != null) {
                String userSub = jwt.getSubject();    // the user's permanent Cognito ID
                markAuthenticated(userSub, request);
                TenantContext.set(cognito.findOrgId(userSub));   // null -> sees nothing
            }
        }
    }

    private boolean tryLocalToken(String token, HttpServletRequest request) {
        String username;
        try {
            username = jwtUtil.extractUsername(token);
        } catch (Exception e) {
            return false;                             // not one of ours (or expired)
        }
        if (username == null || !jwtUtil.isTokenValid(token, username)) {
            return false;
        }
        markAuthenticated(username, request);
        TenantContext.set(jwtUtil.extractOrgId(token));
        return true;
    }

    private void markAuthenticated(String principal, HttpServletRequest request) {
        UsernamePasswordAuthenticationToken authToken =
            new UsernamePasswordAuthenticationToken(principal, null, new ArrayList<>());
        authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        SecurityContextHolder.getContext().setAuthentication(authToken);
    }
}