package com.sedcore.security.services.imp;


import com.sedcore.security.models.request.AuthenticationRequest;
import com.sedcore.security.services.IAuthenticationService;
import com.sedcore.security.services.ITokenService;
import com.sedcore.security.services.IUserDefService;
import com.towpen.base.security.JWT;
import com.towpen.base.security.model.TOpenSessionInstance;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthenticationServiceImp implements IAuthenticationService {

	public static final Long EXPIRE_IN_MINUTES = 60L;

	public static final Long EXPIRE_REFRESH_TOKEN_IN_MINUTES = 120L;


	private final IUserDefService userDefService;


	private final ITokenService tokenService;

	@Override
	public JWT authenticate(AuthenticationRequest loginRequestDto) {
		TOpenSessionInstance instance = userDefService.login(loginRequestDto.getUsername(),loginRequestDto.getPassword());
		return tokenService.createToken(instance,EXPIRE_IN_MINUTES,EXPIRE_REFRESH_TOKEN_IN_MINUTES);
	}
}
