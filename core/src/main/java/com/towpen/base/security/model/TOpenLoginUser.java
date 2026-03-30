package com.towpen.base.security.model;

import com.towpen.base.enums.model.LanguageType;
import lombok.*;

import java.util.HashMap;
import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString(of = { "userName" })
public class TOpenLoginUser {
	private String userId;

	private String userName;

	private String displayName;

	private String selectedCompanyCode;

	private List<TOpenCompanyInfo> supportedCompanies;

	private LanguageType languageVal;

	private HashMap<String, Object> dynamicLoginParameters;

	private String sessionId;

	private String ipAddress;
}
