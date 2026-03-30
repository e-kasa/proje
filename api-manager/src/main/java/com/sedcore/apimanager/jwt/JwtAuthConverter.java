package com.sedcore.apimanager.jwt;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.server.authentication.ServerAuthenticationConverter;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * @deprecated Artık kullanılmıyor. JWT doğrulaması
 *             {@link com.sedcore.apimanager.filter.JwtAuthFilter} tarafından yapılıyor.
 *             {@code @Component} kaldırıldı — Spring context'e yüklenmiyor.
 */
@Deprecated(forRemoval = true)
public class JwtAuthConverter implements ServerAuthenticationConverter {

    @Override
    public Mono<Authentication> convert(ServerWebExchange exchange) {
        return Mono.justOrEmpty(exchange.getRequest().getHeaders().getFirst("Authorization"))
                .filter(h -> h.startsWith("Bearer "))
                .map(h -> h.substring(7))
                .map(token -> new UsernamePasswordAuthenticationToken(null, token));
    }
}
