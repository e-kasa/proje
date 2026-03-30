package com.sedcore.security.services.imp;

import com.google.gson.Gson;
import com.sedcore.security.services.ITokenService;
import com.towpen.base.security.JWT;
import com.towpen.base.security.model.TOpenSessionInstance;
import com.towpen.base.security.util.JwtUtil;
import com.towpen.utils.TDateUtils;
import io.jsonwebtoken.Jwts;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Service
public class TokenService implements ITokenService {

    private static final String KEY_SESSION="sessionInstance";
    private static final String TOKEN_TYPE ="tokenType";
    private static final String TOKEN_TYPE_REFRESH ="new";

    private Key hmacKey ;
    private Gson gson = new Gson();
    @Override
    public JWT createToken(TOpenSessionInstance instance,Long expireInMinutes, Long expireRefreshTokenInMinutes) {
        Map<String,Object> claim = new HashMap<>();
        claim.put(KEY_SESSION,toJson(instance));
        return createToken(claim,instance.getUserInformation().getUserName(),expireInMinutes,expireRefreshTokenInMinutes,instance);
    }
    private String toJson(TOpenSessionInstance instance) {
        return this.gson.toJson(instance);
    }

    private JWT createToken(Map<String,Object> claims,String subject,Long expiresMinutes,Long expireRefreshTokenInMinutes,TOpenSessionInstance instance){
        JWT dtoJWT = new JWT();

        LocalDateTime acessTokenExpiretionDateTime = LocalDateTime.now().plusMinutes(expiresMinutes);

        dtoJWT.setAccessTokenExpiration(acessTokenExpiretionDateTime);

        Map<String,Object> tokenClaimMap = new HashMap<>(claims);
        tokenClaimMap.put(TOKEN_TYPE,TOKEN_TYPE_REFRESH);

        String accessToken = Jwts.builder()
                .setClaims(tokenClaimMap)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(TDateUtils.asDateFromLocalDateTime(acessTokenExpiretionDateTime))
                .signWith(JwtUtil.getSigningKey())
                .compact();
        dtoJWT.setAccessToken(accessToken);
        dtoJWT.setAccessTokenExpireIn(expiresMinutes);

        LocalDateTime refreshTokenExpiretionDateTime = LocalDateTime.now().plusMinutes(expireRefreshTokenInMinutes);

        String refreshToken = Jwts.builder()
                .setClaims(tokenClaimMap)
                .setSubject(subject)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .signWith(JwtUtil.getSigningKey())
                .setExpiration(TDateUtils.asDateFromLocalDateTime(refreshTokenExpiretionDateTime)).compact();

        dtoJWT.setRefreshToken(refreshToken);
        dtoJWT.setSessionId(instance.getUserInformation().getSessionId());
        dtoJWT.setRefreshTokenExpiration(refreshTokenExpiretionDateTime);
        dtoJWT.setRefreshTokenexpireIn(expireRefreshTokenInMinutes);


        return dtoJWT;
    }

}