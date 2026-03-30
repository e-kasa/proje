package com.sedcore.security.services;

import com.towpen.base.security.JWT;
import com.towpen.base.security.model.TOpenSessionInstance;

public interface ITokenService {
    JWT createToken(TOpenSessionInstance instance, Long expireInMinutes, Long expireRefreshTokenInMinutes);
}
