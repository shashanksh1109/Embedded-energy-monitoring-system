package com.energy.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

/**
 * JwtFilter - runs once for every HTTP request.
 *
 * If the request carries a valid token, it:
 *   1. marks the request as authenticated (SecurityContextHolder), and
 *   2. records the token's organization in TenantContext, so every database
 *      query in this request only sees that organization's rows.
 *
 * TenantContext is ALWAYS cleared at the end (finally), because server
 * threads are reused: the next request on this thread must not inherit
 * this request's organization.
 */
@Component
@RequiredArgsConstructor
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

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

        String token = authHeader.substring(7);

        String username;
        try {
            username = jwtUtil.extractUsername(token);
        } catch (Exception e) {
            return;                                   // bad or expired token
        }

        if (username != null
                && SecurityContextHolder.getContext().getAuthentication() == null
                && jwtUtil.isTokenValid(token, username)) {

            UsernamePasswordAuthenticationToken authToken =
                new UsernamePasswordAuthenticationToken(username, null, new ArrayList<>());
            authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authToken);

            // The organization this request works for (null -> sees nothing)
            TenantContext.set(jwtUtil.extractOrgId(token));
        }
    }
}