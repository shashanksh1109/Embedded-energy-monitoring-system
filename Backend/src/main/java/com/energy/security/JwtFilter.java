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
 * JwtFilter - intercepts every HTTP request and validates JWT token
 *
 * Extends OncePerRequestFilter — Spring guarantees this filter
 * runs exactly once per request, never twice.
 *
 * The filter runs BEFORE the request reaches any controller.
 * If the token is invalid, the request is rejected here.
 * If the token is valid, the request continues to the controller.
 */
@Component
@RequiredArgsConstructor
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    /**
     * This method runs for every single incoming HTTP request.
     *
     * Parameters:
     *   request     = the incoming HTTP request
     *   response    = the outgoing HTTP response
     *   filterChain = the chain of filters — calling filterChain.doFilter()
     *                 passes the request to the next filter or controller
     */
    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        // ─────────────────────────────────────────────────
        // STEP 1: Extract the Authorization header
        //
        // JWT tokens are sent in the HTTP Authorization header:
        //   Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
        //
        // "Bearer" is the token type — it just means
        // "the holder of this token is authorized"
        // ─────────────────────────────────────────────────
        String authHeader = request.getHeader("Authorization");

        // If no Authorization header or it doesn't start with "Bearer "
        // this request has no token — pass it through unchanged.
        // SecurityConfig will decide if this endpoint needs a token.
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // ─────────────────────────────────────────────────
        // STEP 2: Extract the token from the header
        //
        // Header:  "Bearer eyJhbGciOiJIUzI1NiJ9..."
        // We skip the first 7 characters ("Bearer ")
        // to get just the token string.
        // ─────────────────────────────────────────────────
        String token = authHeader.substring(7);

        // ─────────────────────────────────────────────────
        // STEP 3: Extract username from the token
        // ─────────────────────────────────────────────────
        String username;
        try {
            username = jwtUtil.extractUsername(token);
        } catch (Exception e) {
            // Token is malformed — can't even parse it
            // Pass through, Spring Security will reject it
            filterChain.doFilter(request, response);
            return;
        }

        // ─────────────────────────────────────────────────
        // STEP 4: Validate the token
        //
        // Only proceed if:
        //   - username was extracted successfully (not null)
        //   - no authentication already exists in context
        //     (avoid processing the same request twice)
        // ─────────────────────────────────────────────────
        if (username != null &&
            SecurityContextHolder.getContext().getAuthentication() == null) {

            // Validate token — checks signature + expiry + username match
            if (jwtUtil.isTokenValid(token, username)) {

                // ─────────────────────────────────────────
                // STEP 5: Set authentication in Spring's
                // Security Context
                //
                // This tells Spring Security:
                // "This request has been authenticated.
                //  The user is: [username]"
                //
                // UsernamePasswordAuthenticationToken represents
                // an authenticated user. Three arguments:
                //   1. principal   = the username (who they are)
                //   2. credentials = null (token already validated)
                //   3. authorities = empty list (no roles yet)
                // ─────────────────────────────────────────
                UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(
                        username,
                        null,
                        new ArrayList<>()
                    );

                // Attach request details (IP address etc.) to the token
                authToken.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
                );

                // Store authentication in the Security Context
                // Spring Security reads this to know the request is authenticated
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // ─────────────────────────────────────────────────
        // STEP 6: Pass request to the next filter/controller
        //
        // Whether the token was valid or not, we always call
        // filterChain.doFilter() — we never block here directly.
        // SecurityConfig decides which endpoints need authentication.
        // If an unauthenticated request reaches a protected endpoint,
        // Spring Security automatically returns HTTP 401.
        // ─────────────────────────────────────────────────
        filterChain.doFilter(request, response);
    }

}