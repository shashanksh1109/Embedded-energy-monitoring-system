package com.energy.config;
import com.energy.security.JwtFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
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
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {
    private final JwtFilter jwtFilter;
    private final CorsConfigurationSource corsConfigurationSource;

    // Only "admin" is a valid username - any other username throws exception -> 401
    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            if (!"admin".equals(username)) {
                throw new UsernameNotFoundException("User not found: " + username);
            }
            return User.withUsername("admin")
                .password(passwordEncoder().encode("energy123"))
                .roles("ADMIN")
                .build();
        };
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource))
            .csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/health").permitAll()
                .requestMatchers("/error").permitAll()
                // Reading the mode is public; CHANGING it (starting/stopping
                // ECS services) now requires a signed-in user
                .requestMatchers(HttpMethod.GET, "/api/mode").permitAll()
                // Devices claim themselves with a one-time code, before any login exists
                .requestMatchers(HttpMethod.POST, "/api/devices/claim").permitAll()
                // Raspberry Pi hubs: ask for a pairing code, and poll with their
                // own hub key (checked in HubController), before any login exists
                .requestMatchers(HttpMethod.POST, "/api/hubs/start").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/hubs/status").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/hubs/sensors").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/hubs/commands").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/hubs/commands/*/ack").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/hubs/outputs").permitAll()
                .requestMatchers(
                    "/swagger-ui.html",
                    "/swagger-ui/**",
                    "/api-docs/**"
                ).permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            // No token, or an expired/invalid one -> 401 Unauthorized ("who are you?").
            // Without this, Spring Security answers 403 Forbidden, which the
            // frontend can't tell apart from "signed in, but not allowed".
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService());
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(
        AuthenticationConfiguration config
    ) throws Exception {
        return config.getAuthenticationManager();
    }
}