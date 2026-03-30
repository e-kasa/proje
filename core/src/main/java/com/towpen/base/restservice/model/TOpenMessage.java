package com.towpen.base.restservice.model;

import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.models.TMessageBundleValue;
import com.towpen.base.exceptions.models.TMessageStaticValue;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
public class TOpenMessage {

	private String messageCode;

	private List<TMessageBaseValue> parameters;

	private TOpenMessage() {
		this.parameters=new ArrayList<>();
	}
	public TOpenMessage(TMessageType mesType) {
		this();
		this.messageCode = mesType.getValue();
	}

	public TOpenMessage(TMessageType mesType,TMessageBaseValue ...params) {
		this(mesType);
		if(params!=null && params.length>0) {
			for (TMessageBaseValue tMessageBaseValue : params) {
				addValue(tMessageBaseValue);
			}
		}
	}

	public TOpenMessage addStaticValue(Object value) {
		this.parameters.add(new TMessageStaticValue(value));
		return this;
	}
	public TOpenMessage addValue(TMessageBaseValue value) {
		this.parameters.add(value);
		return this;
	}
	public TOpenMessage addBundleValue(String bundleCode) {
		this.parameters.add(new TMessageBundleValue(bundleCode));
		return this;
	}
}
