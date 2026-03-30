package com.sedcore.apimanager.filter;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nimbusds.jwt.JWTClaimsSet;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * TOKEN VARSA çalışır — JWT doğrular, company code'u JWT'den çıkarır.
 *
 * Token yoksa bu filter hiçbir şey yapmaz;
 * şirketi CompanyResolutionFilter domain'den çıkarmıştır.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter implements GlobalFilter {

    private final JwtDecoder jwtDecoder;
    private final ObjectMapper objectMapper;

    private static final String HEADER_COMPANY_CODE = "X-Company-Code";
    private static final String HEADER_USER_INFO    = "X-User-Info";

    private static final String[] PUBLIC_PATHS = {
            "/security/authenticate",
            "/security/refresh",
            "/security/company/",
            "/product/api/v1/public/",
            "/actuator/"
    };

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path  = exchange.getRequest().getURI().getPath();
        String auth  = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);

        // Public path — token kontrolü yok
        for (String p : PUBLIC_PATHS) {
            if (path.startsWith(p)) return chain.filter(exchange);
        }

        // Token yok — CompanyResolutionFilter zaten domain'den halletti, geçir
        if (auth == null || !auth.startsWith("Bearer ")) {
            return chain.filter(exchange);
        }

        // Token var — doğrula
        String token = auth.substring(7);
        JWTClaimsSet claims;
        try {
            claims = jwtDecoder.decode(token);
        } catch (Exception e) {
            log.warn("JWT geçersiz: {}", e.getMessage());
            return unauthorized(exchange);
        }

        if (jwtDecoder.isExpired(claims)) {
            log.warn("JWT süresi dolmuş");
            return unauthorized(exchange);
        }

        String sessionInstance = (String) claims.getClaim("sessionInstance");
        String companyCode     = extractCompanyCode(sessionInstance);

        ServerWebExchange mutated = exchange.mutate()
                .request(r -> {
                    r.header(HEADER_USER_INFO, sessionInstance);
                    if (companyCode != null) r.header(HEADER_COMPANY_CODE, companyCode);
                })
                .build();

        return chain.filter(mutated);
    }

    /** sessionInstance JSON'undan selectedCompanyCode'u çıkarır */
    private String extractCompanyCode(String sessionInstanceJson) {
        if (sessionInstanceJson == null || sessionInstanceJson.isBlank()) return null;
        try {
            JsonNode root = objectMapper.readTree(sessionInstanceJson);
            String code   = root.path("userInformation").path("selectedCompanyCode").asText(null);
            return (code != null && !code.isBlank()) ? code : null;
        } catch (Exception e) {
            log.error("sessionInstance parse hatası: {}", e.getMessage());
            return null;
        }
    }

    private Mono<Void> unauthorized(ServerWebExchange exchange) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
    }
}
