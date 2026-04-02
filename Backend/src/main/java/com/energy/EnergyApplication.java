package com.energy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * EnergyApplication - Main entry point
 *
 * @SpringBootApplication does three things in one annotation:
 *   1. @Configuration      - this class can define Spring beans
 *   2. @EnableAutoConfiguration - Spring Boot auto-configures everything
 *                                 (database, security, web server, etc.)
 *   3. @ComponentScan      - scans this package and all sub-packages
 *                            for @Controller, @Service, @Repository etc.
 *
 * When you run this, Spring Boot:
 *   - Starts an embedded Tomcat server on port 8081
 *   - Connects to PostgreSQL using application.properties
 *   - Registers all your controllers, services, repositories
 *   - Sets up JWT security
 *   - Exposes Swagger UI at /swagger-ui.html
 */
@SpringBootApplication
public class EnergyApplication {

    public static void main(String[] args) {
        SpringApplication.run(EnergyApplication.class, args);
    }

}