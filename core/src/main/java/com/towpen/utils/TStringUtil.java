package com.towpen.utils;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.exc.StreamReadException;
import com.fasterxml.jackson.databind.DatabindException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.experimental.UtilityClass;
import org.springframework.lang.Nullable;

import java.io.IOException;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@UtilityClass
public class TStringUtil {

	public static boolean hasText(@Nullable String str) {
		return (str != null && !str.isEmpty() && containsText(str));
	}

	public static String getDefault(String str,String defaultValue) {
		return isBlank(str)?defaultValue:str;
	}

	public static String toString(Object val) {
		return val!=null?val.toString():null;
	}

	public static boolean isBlank(@Nullable String str) {
		return str==null || str.trim().isBlank();
	}

	public static boolean isValid(@Nullable String str) {
		return !isNullOrBlank(str);
	}

	public static boolean isNullOrBlank(@Nullable String str) {
		return isNull(str) || isBlank(str);
	}

	public static boolean isNull(@Nullable String str) {
		return str==null ;
	}

	public static String toUpper(String text) {
		return isNullOrBlank(text)?null:text.toUpperCase(new Locale("tr"));
	}

	private static boolean containsText(CharSequence str) {
		int strLen = str.length();
		for (int i = 0; i < strLen; i++) {
			if (!Character.isWhitespace(str.charAt(i))) {
				return true;
			}
		}
		return false;
	}

	public static boolean isSame(@Nullable String firstStr, @Nullable String secondStr) {
		if(isNull(firstStr) && isNull(secondStr)){
			return true;
		} else if(isNull(firstStr) || isNull(secondStr)) {
			return false;
		}
		return firstStr.trim().equals(secondStr.trim()) ;
	}


	public static boolean isValidPhone(String text) {
		String regex = "0[1-9]{1}[0-9]{9}";
		Pattern patt = Pattern.compile(regex);
		Matcher matcher = patt.matcher(text);
		return matcher.matches();
	}

	public static boolean isValidMobilePhone(String text) {
		String regex = "5[0-9]{9}";
		Pattern patt = Pattern.compile(regex);
		Matcher matcher = patt.matcher(text);
		return matcher.matches();
	}

	public static boolean isValidMailAddress(String text) {
		//		String regex = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\\\.[A-Z]{2,6}$";
		String regex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?";
		Pattern patt = Pattern.compile(regex);
		Matcher matcher = patt.matcher(text);
		return matcher.matches();
	}

	public static boolean isValidUrl(String text) {
		String regex = "^(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]";
		Pattern patt = Pattern.compile(regex);
		Matcher matcher = patt.matcher(text);
		return matcher.matches();
	}

	public static String jsonContentOf(Object object) {
		ObjectMapper mapper = new ObjectMapper();
		mapper.registerModule(new JavaTimeModule());
		String jsonContent = null;
		try {
			jsonContent = mapper.writeValueAsString(object);

		} catch (JsonProcessingException e) {
			e.printStackTrace();
		}
		return jsonContent;
	}

	public static Object objectFromJson(String json, Class c) {
		try {
			ObjectMapper objectMapper = new ObjectMapper();
			objectMapper.registerModule(new JavaTimeModule());
			return objectMapper.readValue(json.getBytes(), c);
		} catch (StreamReadException e) {
			e.printStackTrace();
		} catch (DatabindException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}
}
