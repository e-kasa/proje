package com.sedcore.apimanager.jwt;

import io.jsonwebtoken.Claims;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import reactor.core.publisher.Mono;

/**
 * @deprecated Artık kullanılmıyor. JWT doğrulaması
 *             {@link com.sedcore.apimanager.filter.JwtAuthFilter} tarafından yapılıyor.
 *             {@code @Component} kaldırıldı — Spring context'e yüklenmiyor.
 */
@Deprecated(forRemoval = true)
public class JwtAuthenticationManager implements ReactiveAuthenticationManager {

    @Override
    public Mono<Authentication> authenticate(Authentication authentication) {
        String token = authentication.getCredentials().toString();
        try {
            Claims claims = JwtUtil.validateToken(token);
            return Mono.just(
                    new UsernamePasswordAuthenticationToken(claims.getSubject(), null, null)
            );
        } catch (Exception e) {
            return Mono.empty();
        }
    }
}
