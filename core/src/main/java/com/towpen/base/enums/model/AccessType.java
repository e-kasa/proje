package com.towpen.base.enums.model;

public enum AccessType implements IEnumBundleBase{

	LDAP("access.type.ldap", false), INTERNAL("access.type.internal", true), SSO("access.type.sso", false);

	private String bundleCode;
	private boolean isChangePass;

	AccessType(String code, boolean isChangePass) {
		this.bundleCode = code;
		this.isChangePass = isChangePass;
	}

	@Override
	public String getBundleCode() {
		return this.bundleCode;
	}

	@Override
	public String getValue() {
		return name();
	}

	public boolean isChangePass() {
		return isChangePass;
	}
}
