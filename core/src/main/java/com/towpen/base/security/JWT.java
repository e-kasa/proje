package com.towpen.base.security;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class JWT extends DtoBaseModel {

	private static final long serialVersionUID = 1L;

	private String accessToken;

	private LocalDateTime accessTokenExpiration;

	private Long accessTokenExpireIn;

	private String refreshToken;

	private Long refreshTokenexpireIn;

	private LocalDateTime refreshTokenExpiration;

	private String sessionId;
}
