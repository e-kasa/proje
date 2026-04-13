package com.sedcore.security.controllers;

import com.sedcore.security.models.request.AuthenticationRequest;
import com.sedcore.security.models.request.RefreshTokenRequest;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.security.JWT;
import org.springframework.web.bind.annotation.RequestBody;

public interface RestAuthenticateController {
	RestRootEntity<JWT> login(@RequestBody AuthenticationRequest auth);

	RestRootEntity<JWT> refreshToken(@RequestBody RefreshTokenRequest request);
}
