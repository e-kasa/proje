package com.sedcore.apimanager.jwt;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.experimental.UtilityClass;

import java.nio.charset.StandardCharsets;
import java.security.Key;

@UtilityClass
public  class JwtUtil {

    private static final String SECRET = "BuCokGizliVeUzunBirAnahtarOlmalidir12345!";

    private static Key getSigningKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8));
    }

    public static Claims validateToken(String token) {
        Jws<Claims> claimsJws = Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token);
        return claimsJws.getBody();
    }
}