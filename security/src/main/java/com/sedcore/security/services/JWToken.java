package com.sedcore.security.services;


import org.springframework.stereotype.Service;

@Service
public class JWToken {
    public final String secretKey = "STP";
    public final String Issuer = "localhost";

//    public String  generateToken(User user, int validity){
//        Algorithm algorithm = Algorithm.HMAC256(secretKey);
//        String access_token = JWT.create()
//                .withSubject(user.getUsername())
//                .withExpiresAt(new Date(System.currentTimeMillis() + validity*60*1000))
//                .withIssuer(Issuer)
//                .withClaim("roles", user.getAuthorities().stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList()))
//                .sign(algorithm);
//        return access_token;
//    }
//
//    public UsernamePasswordAuthenticationToken validateToken(String token)
//    {
//        Algorithm algorithm = Algorithm.HMAC256(secretKey);
//        JWTVerifier verifier = JWT.require(algorithm).build();
//        DecodedJWT decodedJWT = verifier.verify(token);
//
//        String username = decodedJWT.getSubject();
//        String[] roles = decodedJWT.getClaim("roles").asArray(String.class);
//        Collection<SimpleGrantedAuthority> authorities = new ArrayList<>();
//        stream(roles).forEach(role -> authorities.add(new SimpleGrantedAuthority(role)));
//
//        UsernamePasswordAuthenticationToken authenticationToken =
//                new UsernamePasswordAuthenticationToken(username, null, authorities);
//        return authenticationToken;
//    }
}
