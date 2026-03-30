package com.sedcore.security.services;

import com.sedcore.security.models.request.AuthenticationRequest;
import com.towpen.base.security.JWT;

public interface IAuthenticationService {

	public JWT authenticate( AuthenticationRequest loginRequestDto);

}
