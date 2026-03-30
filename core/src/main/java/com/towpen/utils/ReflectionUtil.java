package com.towpen.utils;

import lombok.experimental.UtilityClass;

@UtilityClass
public class ReflectionUtil {
	public static boolean isSuperClass(Object o,Class<?>superClass) {
		if(o==null) {
			return false;
		}
		Class<?> clazz = o.getClass();
		while (clazz != null) {
			clazz = clazz.getSuperclass();
			if(clazz!=null && clazz==superClass) {
				return true;
			}
		}
		return false;

	}
}
