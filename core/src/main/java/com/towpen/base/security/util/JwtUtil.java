package com.towpen.base.security.util;

import io.jsonwebtoken.security.Keys;
import lombok.experimental.UtilityClass;

import java.nio.charset.StandardCharsets;
import java.security.Key;

@UtilityClass
public class JwtUtil {

    /**
     * @deprecated Secret hardcoded — yeni kodlarda {@link #getSigningKey(String)} kullanın.
     *             application.properties'ten {@code @Value("${jwt.secret}")} ile alınan
     *             değeri bu metoda geçirin.
     */
    @Deprecated
    public Key getSigningKey() {
        // Geriye dönük uyumluluk için kalıyor; kaldırılacak.
        return getSigningKey("BuCokGizliVeUzunBirAnahtarOlmalidir12345!");
    }

    /**
     * Verilen secret string'den HMAC-SHA256 imza anahtarı üretir.
     * Secret değerini her zaman application.properties/yml'den @Value ile okuyun.
     */
    public Key getSigningKey(String secret) {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

}