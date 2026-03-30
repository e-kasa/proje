package com.sedcore.apimanager.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.context.NoOpServerSecurityContextRepository;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsConfigurationSource;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

/**
 * Spring Security (WebFlux) yapılandırması.
 *
 * <p>JWT doğrulaması {@link com.sedcore.apimanager.filter.JwtAuthFilter} tarafından yapılır.
 * Bu sınıf yalnızca CSRF/CORS/OPTIONS için devreye girer.
 *
 * <p>CORS: allowedOrigins application.yml'den okunur; Spring Security ve
 * Spring Cloud Gateway aynı kaynağı paylaşır. İki çakışan kural yoktur.
 */
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    /**
     * application.yml → spring.cloud.gateway.server.webflux.globalcors
     * altındaki origin listesiyle senkronize tutulmalıdır.
     * Geliştirme sırasında * da kullanılabilir; production'da açık liste zorunludur.
     */
    @Value("${cors.allowed-origins:http://localhost:3000,http://localhost:3001,http://localhost:5173,http://localhost:8081,https://www.sedcore.com,https://www.bertspot.com}")
    private String allowedOriginsRaw;

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {

        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .authorizeExchange(ex -> ex
                        .pathMatchers(
                                "/security/authenticate",
                                "/security/company/resolve",
                                "/product/api/v1/public/**",
                                "/actuator/**",
                                "/eureka/**"
                        ).permitAll()
                        .pathMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        // Gerçek JWT kontrolü JwtAuthFilter (GlobalFilter) yapıyor
                        .anyExchange().permitAll()
                )
                .securityContextRepository(NoOpServerSecurityContextRepository.getInstance())
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .formLogin(ServerHttpSecurity.FormLoginSpec::disable);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // allowedOriginPatterns: wildcard destekler ("http://localhost:*") ve
        // allowCredentials:true ile çakışmaz (allowedOrigins("*") çakışır).
        // Sabit production origin'leri de buraya eklenir.
        List<String> patterns = Arrays.stream(allowedOriginsRaw.split(","))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .toList();
        config.setAllowedOriginPatterns(patterns);

        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization", "X-User-Info", "X-Company-Code"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L); // preflight cache süresi (saniye)

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
