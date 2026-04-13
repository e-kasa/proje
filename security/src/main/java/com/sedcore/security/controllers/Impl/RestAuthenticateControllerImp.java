package com.sedcore.security.controllers.Impl;

import com.sedcore.security.models.request.AuthenticationRequest;
import com.sedcore.security.models.request.RefreshTokenRequest;
import com.sedcore.security.services.IAuthenticationService;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.security.JWT;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class RestAuthenticateControllerImp {

	private final IAuthenticationService authService;

	@PostMapping("/authenticate")
	public RestRootEntity<JWT> login(@RequestBody AuthenticationRequest auth) {
		return RestRootEntity.ok(authService.authenticate(auth));
	}

	@PostMapping("/api/v1/auth/refresh-token")
	public RestRootEntity<JWT> refreshToken(@RequestBody RefreshTokenRequest request) {
		return RestRootEntity.ok(authService.refreshToken(request.getRefreshToken()));
	}
}
