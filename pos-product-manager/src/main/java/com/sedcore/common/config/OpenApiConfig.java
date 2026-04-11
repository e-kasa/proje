package com.sedcore.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI Configuration for POS Product Manager Service
 *
 * Defines API documentation using OpenAPI 3.0 specification
 * Accessible at: http://localhost:8080/swagger-ui.html
 *
 * Provides:
 * - Service metadata and contact information
 * - API endpoint documentation
 * - Security scheme definition (JWT Bearer)
 * - Standardized error response documentation
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("POS Product Manager API")
                        .version("1.0.0")
                        .description("RESTful API for POS Product Management System\n\n" +
                                "Provides endpoints for:\n" +
                                "- Product and Variant Management\n" +
                                "- Stock Movement Tracking (Sales, Purchases, Transfers)\n" +
                                "- Product Recommendations (Hybrid: Frequently Bought Together + Similar Products)\n" +
                                "- Sale Processing and Returns\n" +
                                "- Stock Count and Adjustments\n" +
                                "\n" +
                                "Multi-tenant architecture with company-level data isolation.\n" +
                                "All requests require valid JWT token in Authorization header.")
                        .contact(new Contact()
                                .name("POS Development Team")
                                .email("support@pos.example.com")
                                .url("https://pos.example.com"))
                        .license(new License()
                                .name("Proprietary")
                                .url("https://pos.example.com/license")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
                .components(new io.swagger.v3.oas.models.Components()
                        .addSecuritySchemes("Bearer Authentication",
                                new SecurityScheme()
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("Enter JWT token")));
    }
}
