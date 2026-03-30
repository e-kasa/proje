package com.towpen.base.enums.model;

public enum SortType implements IEnumBundleBase{
	ASCENDING("general.sort.asc"), DESCENDING("general.sort.desc"), SPECIAL_ORDER("general.sort.special-order");

	private SortType(String bundleCode) {
		this.bundleCode = bundleCode;
	}

	private String bundleCode;

	@Override
	public String getBundleCode() {
		return this.bundleCode;
	}

	@Override
	public String getValue() {
		return name();
	}
}
