package com.sedcore.security.config;

import com.towpen.base.exceptions.rest.ApiErrorBeanController;
import com.towpen.base.security.filter.JwtXUserInfoFilter;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.security.web.util.matcher.AntPathRequestMatcher;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfiguration {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http, @Autowired ApiErrorBeanController api) throws Exception {

        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                    .requestMatchers(
                            AntPathRequestMatcher.antMatcher("/authenticate"),
                            AntPathRequestMatcher.antMatcher("/register/company"),
                            AntPathRequestMatcher.antMatcher("/i18n/**"),
                            AntPathRequestMatcher.antMatcher("/api/v1/auth/refresh-token"),
                            AntPathRequestMatcher.antMatcher("/api/refresh-token"),
                            AntPathRequestMatcher.antMatcher("/api/ldap-authentication"),
                            AntPathRequestMatcher.antMatcher("/api/sso-log"),
                            AntPathRequestMatcher.antMatcher("/actuator/**"),
                            AntPathRequestMatcher.antMatcher("/h2-console/**")
                    ).permitAll()
                    .anyRequest().authenticated()
            )
            .exceptionHandling(ex -> ex
                    .authenticationEntryPoint(
                            (request, response, authException) ->
                                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, authException.getMessage())
                    )
            );

        http.addFilterBefore(new JwtXUserInfoFilter(api), BasicAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public AuthenticationEntryPoint unauthorizedEntryPoint() {
        return (request, response, authException) -> response.sendError(HttpServletResponse.SC_UNAUTHORIZED, authException.getMessage());
    }

    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return web -> web.ignoring().requestMatchers(
                AntPathRequestMatcher.antMatcher("/swagger-ui/**"),
                AntPathRequestMatcher.antMatcher("/error"),
                AntPathRequestMatcher.antMatcher("/v3/**"),
                AntPathRequestMatcher.antMatcher("/h2-console/**")
        );
    }
}
