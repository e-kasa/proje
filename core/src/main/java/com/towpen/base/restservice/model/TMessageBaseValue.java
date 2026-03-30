package com.towpen.base.restservice.model;

import com.towpen.base.enums.model.TMessageParameterType;
import lombok.Getter;

@Getter
public class TMessageBaseValue {
	protected TMessageParameterType parameterType;

	public TMessageBaseValue(TMessageParameterType parameterType) {
		this.parameterType=parameterType;
	}

	public boolean isBundleParameter() {
		return parameterType!=null && parameterType==TMessageParameterType.BUNDLE;
	}
	public boolean isStaticParameter() {
		return parameterType!=null && parameterType==TMessageParameterType.STATIC;
	}
}
