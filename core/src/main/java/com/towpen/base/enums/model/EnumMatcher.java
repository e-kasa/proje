package com.towpen.base.enums.model;

import java.util.HashMap;
import java.util.Map;

public class EnumMatcher {
	private EnumMatcher() {

	}
	public static final String KEY_AVAILABLE_SUB_BRANCH = "AVAILABLE_SUB_BRANCH_TYPE";

	public static final String KEY_EBS_INVOICE_STATUS = "EBS_INVOICE_STATUS";

	private static Map<String, Class<?>> typeMasterMap = new HashMap<>();
	private static Map<Class<?>, String> enumMap = new HashMap<>();

	static {// PolicyStatu
		//put(KEY_AVAILABLE_SUB_BRANCH, AvailableSubBranch.class);
	}

	public static Class<?> getEnumClass(String key) {
		return typeMasterMap.get(key);
	}

	public static String getTypeMasterShortCode(Class<?> clazz) {
		return enumMap.get(clazz);
	}

	private static void put(String key, Class<?> clazz) {
		typeMasterMap.put(key, clazz);
		enumMap.put(clazz, key);
	}

}
