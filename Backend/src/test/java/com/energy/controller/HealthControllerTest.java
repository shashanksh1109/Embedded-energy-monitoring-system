package com.energy.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import com.energy.config.SecurityConfig;
import com.energy.config.CorsConfig;
import com.energy.security.JwtFilter;
import com.energy.security.JwtUtil;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// @WebMvcTest loads only the web layer — no database, no full context
// Much faster than @SpringBootTest
@WebMvcTest(HealthController.class)
@Import({SecurityConfig.class, CorsConfig.class, JwtFilter.class, JwtUtil.class})
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;  // simulates HTTP requests without a real server

    @Test
    void healthEndpoint_shouldReturn200() throws Exception {
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk());
    }

    @Test
    void healthEndpoint_shouldReturnStatusUp() throws Exception {
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void healthEndpoint_shouldReturnServiceName() throws Exception {
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.service").value("energy-management-api"));
    }

    @Test
    void healthEndpoint_shouldNotRequireAuthentication() throws Exception {
        // No Authorization header — should still return 200
        // If this returns 401, our SecurityConfig permitAll is broken
        mockMvc.perform(get("/api/health"))
            .andExpect(status().isOk());
    }
}
