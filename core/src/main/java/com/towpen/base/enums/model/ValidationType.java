package com.towpen.base.enums.model;

public enum ValidationType implements IEnumBundleBase{
	NOT_NULL("NotNull",TMessageType.FIELD_IS_REQUIRED_1001,true,1),
	NOT_BLANK("NotBlank",TMessageType.FIELD_IS_REQUIRED_1001,true,1),
	NOT_EMPTY("NotEmpty",TMessageType.FIELD_IS_REQUIRED_1001,true,1),
	SIZE("Size",TMessageType.BETWEEN_MIN_AND_MAX_1002,true,2),
	MIN("Min",TMessageType.VALIDATION_MIN_SIZE_1032,true,1),
	MAX("Max",TMessageType.VALIDATION_MAX_SIZE_1033,true,1);

	private ValidationType(String springCode,TMessageType messageType,boolean hasAnyParameter,Integer parameterCount) {
		this.springCode=springCode;
		this.messageType=messageType;
		this.hasAnyParameter=hasAnyParameter;
		this.parameterCount=parameterCount;
	}

	private boolean hasAnyParameter;

	private String springCode;

	private TMessageType messageType;

	private int parameterCount;


	public boolean isHasAnyParameter() {
		return hasAnyParameter;
	}


	public int getParameterCount() {
		return parameterCount;
	}


	public String getSpringCode() {
		return springCode;
	}

	public static ValidationType getValidationType(String springCode) {
		ValidationType[] vals = values();
		for (ValidationType validationType : vals) {
			if(validationType.getSpringCode().equals(springCode)) {
				return validationType;
			}
		}
		return null;
	}

	@Override
	public String getBundleCode() {
		return this.messageType.getBundleCode();
	}

	@Override
	public String getValue() {
		return name();
	}
}
