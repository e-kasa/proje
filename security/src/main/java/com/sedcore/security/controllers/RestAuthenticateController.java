package com.sedcore.security.controllers;

import com.sedcore.security.models.request.AuthenticationRequest;
import com.sedcore.security.models.request.RefreshTokenRequest;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.security.JWT;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

public interface RestAuthenticateController {

	@PostMapping("/authenticate")
	RestRootEntity<JWT> login(@RequestBody AuthenticationRequest auth);

	@PostMapping("/api/v1/auth/refresh-token")
	RestRootEntity<JWT> refreshToken(@RequestBody RefreshTokenRequest request);
}
