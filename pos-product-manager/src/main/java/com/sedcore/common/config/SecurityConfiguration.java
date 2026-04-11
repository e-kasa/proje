package com.sedcore.common.config;

import com.towpen.base.exceptions.rest.ApiErrorBeanController;
import com.towpen.base.security.filter.JwtXUserInfoFilter;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfiguration {


    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http,@Autowired ApiErrorBeanController api) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/authenticate").permitAll()
                        .requestMatchers(
                                "/api/refresh-token",
                                "/api/ldap-authentication",
                                "/api/sso-log",
                                "/actuator/**",
                                "/h2-console/**"
                        ).permitAll()
                        // Herkese açık e-ticaret endpoint'leri
                        // JWT gerekmez; sadece X-Company-Code header'ı zorunludur
                        .requestMatchers("/api/v1/public/**").permitAll()
                        .anyRequest().authenticated()
                )
                .httpBasic(Customizer.withDefaults());
        http = http.addFilterBefore(new JwtXUserInfoFilter(api), BasicAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public AuthenticationEntryPoint unauthorizedEntryPoint() {
        return (request, response, authException) -> response.sendError(HttpServletResponse.SC_UNAUTHORIZED, authException.getMessage());
    }
}