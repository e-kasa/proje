package com.sedcore.apimanager.filter;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * TOKEN YOKSA çalışır — domain'den company bulur.
 *
 * Token varsa bu filter hiçbir şey yapmaz;
 * şirketi JwtAuthFilter JWT'den çıkarır.
 */
@Slf4j
@Component
public class CompanyResolutionFilter implements GlobalFilter, Ordered {

    public static final String HEADER_COMPANY_CODE = "X-Company-Code";

    @Value("${company.resolution.security-url:http://localhost:8002}")
    private String securityBaseUrl;

    @Value("${company.resolution.fallback-company-code:}")
    private String fallbackCompanyCode;

    private final Cache<String, String> domainCache = Caffeine.newBuilder()
            .expireAfterWrite(30, TimeUnit.MINUTES)
            .maximumSize(1_000)
            .build();

    private final WebClient webClient = WebClient.builder().build();

    @Override
    public int getOrder() {
        return -2; // JwtAuthFilter'dan önce çalış
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();

        // 1. Login / refresh gibi public path'ler — dokunma
        if (isPublicPath(path)) {
            return chain.filter(exchange);
        }

        // 2. Token varsa bu filter'ın işi yok — JwtAuthFilter halleder
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return chain.filter(exchange);
        }

        // 3. Token yok → Origin'den domain bul → X-Company-Code ekle
        String origin = exchange.getRequest().getHeaders().getFirst(HttpHeaders.ORIGIN);
        if (origin == null || origin.isBlank()) {
            origin = exchange.getRequest().getHeaders().getFirst(HttpHeaders.REFERER);
        }

        if (origin == null || origin.isBlank()) {
            // Origin da yok (curl/Postman vb.) — fallback veya geçir
            return proceedWithCode(exchange, chain, fallbackCompanyCode);
        }

        String domain = extractDomain(origin);

        String cached = domainCache.getIfPresent(domain);
        if (cached != null) {
            return proceedWithCode(exchange, chain, cached);
        }

        return resolveFromSecurityService(domain)
                .flatMap(code -> {
                    if (!code.isBlank()) {
                        domainCache.put(domain, code);
                        log.info("Domain çözümlendi: {} → {}", domain, code);
                    } else {
                        log.warn("Domain çözümlenemedi: {}", domain);
                    }
                    return proceedWithCode(exchange, chain, code.isBlank() ? fallbackCompanyCode : code);
                })
                .onErrorResume(e -> {
                    log.error("Security servisi hatası: {}", e.getMessage());
                    return proceedWithCode(exchange, chain, fallbackCompanyCode);
                });
    }

    private Mono<Void> proceedWithCode(ServerWebExchange exchange, GatewayFilterChain chain, String code) {
        if (code == null || code.isBlank()) {
            return chain.filter(exchange); // code yoksa geçir, JwtAuthFilter karar verir
        }
        ServerWebExchange mutated = exchange.mutate()
                .request(r -> r.header(HEADER_COMPANY_CODE, code))
                .build();
        return chain.filter(mutated);
    }

    private boolean isPublicPath(String path) {
        return path.equals("/security/authenticate")
                || path.startsWith("/security/api/v1/auth/refresh-token")
                || path.startsWith("/security/company/")
                || path.startsWith("/actuator/");
    }

    private Mono<String> resolveFromSecurityService(String domain) {
        return webClient.get()
                .uri(URI.create(securityBaseUrl + "/security/company/resolve?domain=" + domain))
                .retrieve()
                .bodyToMono(CompanyResolveResponse.class)
                .timeout(Duration.ofSeconds(3))
                .map(resp -> resp != null && resp.getData() != null ? resp.getData() : "")
                .onErrorReturn("");
    }

    private String extractDomain(String raw) {
        try {
            URI uri = URI.create(raw.trim());
            String host = uri.getHost();
            return host != null ? host.toLowerCase() : raw.toLowerCase().trim();
        } catch (Exception e) {
            return raw.replaceFirst("^https?://", "").split("[/:?]")[0].toLowerCase().trim();
        }
    }

    static class CompanyResolveResponse {
        private String data;
        private Boolean success;
        public String getData() { return data; }
        public void setData(String data) { this.data = data; }
        public Boolean getSuccess() { return success; }
        public void setSuccess(Boolean success) { this.success = success; }
    }
}
