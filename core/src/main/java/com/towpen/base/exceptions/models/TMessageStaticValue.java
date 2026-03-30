package com.towpen.base.exceptions.models;

import com.towpen.base.enums.model.TMessageParameterType;
import com.towpen.base.restservice.model.TMessageBaseValue;
import lombok.Getter;

@Getter
public class TMessageStaticValue extends TMessageBaseValue {
	private String value;

	public TMessageStaticValue(TMessageParameterType parameterType) {
		super(TMessageParameterType.STATIC);
	}

	public TMessageStaticValue(Object value) {
		this(TMessageParameterType.STATIC);
		this.value=value!=null ?value.toString():"";
	}
}
