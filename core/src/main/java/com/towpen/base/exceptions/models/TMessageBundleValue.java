package com.towpen.base.exceptions.models;

import com.towpen.base.enums.model.TMessageParameterType;
import com.towpen.base.restservice.model.TMessageBaseValue;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TMessageBundleValue extends TMessageBaseValue {

	private String  code;

	public TMessageBundleValue(TMessageParameterType parameterType) {
		super(TMessageParameterType.BUNDLE);
	}

	public TMessageBundleValue(String code) {
		this(TMessageParameterType.BUNDLE);
		this.code=code;
	}
}
