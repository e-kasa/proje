package com.towpen.utils;

import lombok.experimental.UtilityClass;
import org.apache.commons.lang3.RandomStringUtils;

@UtilityClass
public class RandomUtil {
	private static final Integer SESSION_CHARACTER_COUNT = 8;

	public static String createRandomAlphanumeric(int length) {
		return RandomStringUtils.randomAlphabetic(length);
	}

	public static String createSessionKey() {
		return RandomStringUtils.randomAlphanumeric(SESSION_CHARACTER_COUNT);
	}
}
