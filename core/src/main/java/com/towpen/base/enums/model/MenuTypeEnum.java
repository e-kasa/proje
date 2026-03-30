package com.towpen.base.enums.model;

public enum MenuTypeEnum {

	MENU("menu.type.menu"),
	FOLDER("menu.type.folder"),
	FRAME("menu.type.frame"),
	EXTERNAL("menu.type.external");

	private String bundleCode;

	private MenuTypeEnum(String bundleCode) {
		this.bundleCode = bundleCode;
	}


	public String getBundleCode() {
		return this.bundleCode;
	}


	public String getValue() {
		return name();
	}

}
