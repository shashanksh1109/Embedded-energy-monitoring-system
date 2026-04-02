package com.energy.config;

import com.energy.security.JwtFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * SecurityConfig - configures Spring Security for the entire application
 *
 * @Configuration = this class defines Spring beans.
 *   Methods annotated with @Bean return objects Spring manages.
 *
 * @EnableWebSecurity = activates Spring Security's web security support.
 *   Without this, security is not applied even if Spring Security
 *   is on the classpath.
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtFilter jwtFilter;

    /**
     * SecurityFilterChain - the main security configuration
     *
     * @Bean = Spring calls this method at startup and manages
     * the returned object as a bean. Other parts of the app
     * can inject SecurityFilterChain if they need it.
     *
     * HttpSecurity = a builder for configuring web security.
     * You chain method calls to define rules.
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // ─────────────────────────────────────────────
            // CSRF protection — disable it
            //
            // CSRF (Cross-Site Request Forgery) protection is
            // needed for browser-based form submissions.
            // REST APIs using JWT don't need it — the token
            // itself prevents CSRF attacks.
            // ─────────────────────────────────────────────
            .csrf(AbstractHttpConfigurer::disable)

            // ─────────────────────────────────────────────
            // Authorization rules — who can access what
            //
            // requestMatchers() = match specific URL patterns
            // permitAll()       = allow everyone, no token needed
            // anyRequest()      = everything else
            // authenticated()   = requires a valid JWT token
            // ─────────────────────────────────────────────
            .authorizeHttpRequests(auth -> auth

                // Login endpoint — must be public
                // (you can't require a token to GET a token)
                .requestMatchers("/api/auth/**").permitAll()

                // Swagger UI — public so you can browse the API
                // without logging in first
                .requestMatchers(
                    "/swagger-ui.html",
                    "/swagger-ui/**",
                    "/api-docs/**"
                ).permitAll()

                // Everything else requires authentication
                .anyRequest().authenticated()
            )

            // ─────────────────────────────────────────────
            // Session management — STATELESS
            //
            // Traditional web apps store session data on the server
            // and give the browser a session cookie.
            // REST APIs with JWT are stateless — the server stores
            // nothing. Every request is self-contained with its token.
            //
            // STATELESS tells Spring Security:
            // "Never create an HTTP session. Every request must
            //  authenticate itself via the JWT token."
            // ─────────────────────────────────────────────
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )

            // ─────────────────────────────────────────────
            // Authentication provider
            //
            // Tells Spring Security HOW to verify credentials.
            // DaoAuthenticationProvider uses UserDetailsService
            // to load the user and PasswordEncoder to check password.
            // ─────────────────────────────────────────────
            .authenticationProvider(authenticationProvider())

            // ─────────────────────────────────────────────
            // Add JwtFilter to the filter chain
            //
            // addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            // means: run JwtFilter BEFORE Spring's default
            // username/password filter.
            //
            // This ensures every request is checked for a JWT token
            // before any other authentication mechanism runs.
            // ─────────────────────────────────────────────
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    /**
     * UserDetailsService - loads user details by username
     *
     * Spring Security calls this when authenticating a login request.
     * It needs to know: "given this username, what is the user's
     * stored password and roles?"
     *
     * For this project we hardcode one admin user.
     * In a production system you'd load from a users table in the DB.
     *
     * User.withUsername() is a Spring Security builder for
     * creating in-memory users.
     */
    @Bean
    public UserDetailsService userDetailsService() {
        return username -> User.withUsername("admin")
            .password(passwordEncoder().encode("energy123"))
            .roles("ADMIN")
            .build();
    }

    /**
     * PasswordEncoder - how passwords are hashed
     *
     * BCrypt is the industry standard password hashing algorithm.
     * It's slow by design — makes brute force attacks impractical.
     *
     * NEVER store plain text passwords.
     * BCryptPasswordEncoder hashes "energy123" → "$2a$10$..."
     * When login happens, it hashes the input and compares
     * to the stored hash. Never decrypts — one way only.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * AuthenticationProvider - wires UserDetailsService + PasswordEncoder
     *
     * DaoAuthenticationProvider connects the two pieces:
     *   1. Load user details via UserDetailsService
     *   2. Verify password via PasswordEncoder
     *
     * This is what AuthenticationManager uses internally
     * when AuthController calls authenticate().
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService());
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    /**
     * AuthenticationManager - Spring Security's central authenticator
     *
     * This is the bean injected into AuthController.
     * AuthenticationConfiguration provides the default manager
     * already configured with our AuthenticationProvider.
     */
    @Bean
    public AuthenticationManager authenticationManager(
        AuthenticationConfiguration config
    ) throws Exception {
        return config.getAuthenticationManager();
    }

}