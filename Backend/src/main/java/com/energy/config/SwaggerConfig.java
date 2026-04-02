package com.energy.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * SwaggerConfig - configures the OpenAPI / Swagger UI documentation
 *
 * SpringDoc auto-scans all @RestController classes and generates
 * API documentation automatically. This config adds:
 *   - Project metadata (name, description, version, contact)
 *   - JWT authentication support in the Swagger UI
 *     (so you can log in and test protected endpoints)
 */
@Configuration
public class SwaggerConfig {

    /**
     * OpenAPI bean — the root configuration object for Swagger UI
     *
     * OpenAPI is the specification standard for REST API documentation.
     * Swagger UI is the visual interface that renders it.
     *
     * What this configures:
     *   info()       → project metadata shown at the top of Swagger UI
     *   components() → reusable definitions — here the JWT security scheme
     *   addSecurityItem() → applies JWT auth to all endpoints by default
     */
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()

            // ─────────────────────────────────────────────
            // Project metadata
            // Shown at the top of the Swagger UI page
            // ─────────────────────────────────────────────
            .info(new Info()
                .title("Energy Monitoring System API")
                .description(
                    "REST API for the Embedded Energy Monitoring System. " +
                    "Provides real-time and historical data for temperature, " +
                    "occupancy, HVAC state, power consumption, and analytics " +
                    "across building zones."
                )
                .version("1.0.0")
                .contact(new Contact()
                    .name("Shashank Sakrappa Hakari")
                    .email("sh.s@northeastern.edu")
                )
            )

            // ─────────────────────────────────────────────
            // JWT Security Scheme
            //
            // This adds an "Authorize" button to Swagger UI.
            // You paste your JWT token there and Swagger
            // automatically includes it in every test request
            // as: Authorization: Bearer <token>
            //
            // SecurityScheme defines HOW authentication works:
            //   type = HTTP        → uses HTTP authentication
            //   scheme = bearer    → uses Bearer token scheme
            //   bearerFormat = JWT → hint that the token is JWT
            //   in = HEADER        → token goes in request header
            // ─────────────────────────────────────────────
            .components(new Components()
                .addSecuritySchemes("bearerAuth",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")
                        .in(SecurityScheme.In.HEADER)
                        .name("Authorization")
                        .description("Enter your JWT token. Get one from POST /api/auth/login")
                )
            )

            // Apply JWT security to all endpoints by default
            // Individual endpoints can override this if needed
            .addSecurityItem(new SecurityRequirement()
                .addList("bearerAuth")
            );
    }

}