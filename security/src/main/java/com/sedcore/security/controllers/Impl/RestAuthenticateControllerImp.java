package com.sedcore.security.controllers.Impl;


import com.sedcore.security.controllers.RestAuthenticateController;
import com.sedcore.security.models.request.AuthenticationRequest;
import com.sedcore.security.models.request.RefreshTokenRequest;
import com.sedcore.security.services.IAuthenticationService;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.security.JWT;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RestAuthenticateControllerImp implements RestAuthenticateController {

	@Autowired
	private IAuthenticationService authService;

	@Override
	@PostMapping("/authenticate")
	public RestRootEntity<JWT> login(@RequestBody AuthenticationRequest auth) {
		return RestRootEntity.ok(authService.authenticate(auth));
	}

	@Override
	@PostMapping("/api/v1/auth/refresh-token")
	public RestRootEntity<JWT> refreshToken(@RequestBody RefreshTokenRequest request) {
		return RestRootEntity.ok(authService.refreshToken(request.getRefreshToken()));
	}
}
