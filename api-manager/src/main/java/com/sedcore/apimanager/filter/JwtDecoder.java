package com.sedcore.apimanager.filter;

import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT token doğrulayıcı.
 *
 * <p>İki adımda çalışır:
 * <ol>
 *   <li>HMAC-SHA256 imzası doğrulanır — manipüle edilmiş token reddedilir.</li>
 *   <li>Claims parse edilir — expiration, subject, sessionInstance okunur.</li>
 * </ol>
 *
 * <p>Secret, {@code jwt.secret} property'sinden okunur.
 *    Security servisi (TokenService) aynı secret ile token üretmelidir.
 */
@Component
public class JwtDecoder {

    @Value("${jwt.secret}")
    private String jwtSecret;

    /**
     * Token'ı parse EDER ve HMAC-SHA256 imzasını DOĞRULAR.
     *
     * @throws RuntimeException imza geçersizse veya parse hatası olursa
     */
    public JWTClaimsSet decode(String token) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(token);

            // İmza doğrulaması — manipüle edilmiş token burada reddedilir
            SecretKey secretKey = new SecretKeySpec(
                    jwtSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            JWSVerifier verifier = new MACVerifier(secretKey);

            if (!signedJWT.verify(verifier)) {
                throw new SecurityException("JWT imzası geçersiz — token reddedildi");
            }

            return signedJWT.getJWTClaimsSet();

        } catch (SecurityException e) {
            throw new RuntimeException(e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("Token parse veya doğrulama hatası", e);
        }
    }

    /**
     * Token'ın süresi dolmuş mu?
     * JJWT'nin aksine Nimbus expiration'ı otomatik kontrol etmez;
     * bu yüzden açıkça kontrol ediyoruz.
     */
    public boolean isExpired(JWTClaimsSet claimsSet) {
        try {
            Date exp = claimsSet.getExpirationTime();
            return exp == null || exp.before(new Date());
        } catch (Exception e) {
            return true; // parse hatası → süresi dolmuş say
        }
    }
}
