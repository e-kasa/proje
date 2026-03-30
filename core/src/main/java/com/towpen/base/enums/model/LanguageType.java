package com.towpen.base.enums.model;
import com.towpen.utils.TStringUtil;

import java.util.Locale;

public enum LanguageType implements IEnumBundleBase{
	TR(new Locale("tr","TR"),"general.language.tr"),
	EN(new Locale("en","EN"),"general.language.en");


	public static final LanguageType DEFAULT_LANGUAGE=TR;
	private LanguageType(Locale locale,String bundleCode) {
		this.locale=locale;
		this.bundleCode=bundleCode;
	}

	private String bundleCode;


	public String getBundleCode() {
		return bundleCode;
	}

	protected void setBundleCode(String bundleCode) {
		this.bundleCode = bundleCode;
	}

	private Locale locale;

	public static LanguageType getLanguageFromValue(String languageStr) {
		return TStringUtil.isNullOrBlank(languageStr)?LanguageType.TR:LanguageType.valueOf(languageStr);
	}

	public Locale getLocale() {
		return locale;
	}
	public static LanguageType getLanguageType(Locale locale) {
		LanguageType[] languageTypes = values();
		for (LanguageType languageType : languageTypes) {
			if(languageType.getLocale().equals(locale)) {
				return languageType;
			}
		}
		return null;
	}

	@Override
	public String getValue() {
		return name();
	}
}
