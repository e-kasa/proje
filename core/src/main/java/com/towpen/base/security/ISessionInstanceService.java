package com.towpen.base.security;

import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.security.model.TOpenCompanyInfo;
import com.towpen.base.security.model.TOpenSessionInstance;
import org.springframework.security.core.Authentication;

import java.util.*;

public interface ISessionInstanceService {
	boolean isLoggedIn();

	String getSelectedCompanyCode();

	List<TOpenCompanyInfo> getSupportedCompanies();

	String getUserCode();
	String getUserId();

	Authentication getAuthentication();

	TOpenSessionInstance getSessionInstance();

	LanguageType getLanguage();

	String getSessionId();
}
