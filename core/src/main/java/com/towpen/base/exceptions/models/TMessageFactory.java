package com.towpen.base.exceptions.models;

import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.restservice.model.TOpenMessage;
import lombok.experimental.UtilityClass;

@UtilityClass
public class TMessageFactory {
	public static TMessageStaticValue ofStatic(Object value) {
		return new TMessageStaticValue(value);
	}

	public static TMessageBundleValue ofBundle(String bundleCode) {
		return new TMessageBundleValue(bundleCode);
	}

	public static TOpenMessage ofMessage(String bundleCode) {
		return new TOpenMessage(TMessageType.getMessageType(bundleCode));
	}
}
