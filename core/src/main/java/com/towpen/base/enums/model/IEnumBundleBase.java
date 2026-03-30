package com.towpen.base.enums.model;

import com.towpen.base.enums.model.EnumMatcher;

public interface IEnumBundleBase {
	String getBundleCode();

	String getValue();

	default String getTypeMasterCode() {

		return EnumMatcher.getTypeMasterShortCode(getClass());
	}
}
