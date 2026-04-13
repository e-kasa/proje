package com.sedcore.security.services;

import com.sedcore.security.models.request.AuthenticationRequest;
import com.towpen.base.security.JWT;

public interface IAuthenticationService {

	JWT authenticate(AuthenticationRequest loginRequestDto);

	JWT refreshToken(String refreshToken);

}
