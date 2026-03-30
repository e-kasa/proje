package com.towpen.base.security.model;

import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString(of = { "code", "name" })
public class TOpenCompanyInfo {

	private boolean defaultCompany;

	private String code;

	private String name;
}
