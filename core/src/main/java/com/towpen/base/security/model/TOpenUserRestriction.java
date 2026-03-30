package com.towpen.base.security.model;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TOpenUserRestriction {
	private String code;
	private String regex;
	private String mode;
}
