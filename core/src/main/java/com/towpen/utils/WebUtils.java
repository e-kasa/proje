package com.towpen.utils;

import jakarta.servlet.http.HttpServletRequest;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.HashSet;
import java.util.Set;

public class WebUtils {

	private static Set<String> HEADERS_IP;

	static {
		HEADERS_IP=new HashSet<>();
		HEADERS_IP.add("HTTP_X_FORWARDED_FOR");
		HEADERS_IP.add("x-forwarded-for");
		HEADERS_IP.add("X_FORWARDED_FOR");
		HEADERS_IP.add("Source_IP");
		HEADERS_IP.add("X-Real-Ip");


	}



	private static String getRedirectionRemoteAddress(HttpServletRequest httpRequest) {
		for (String ipHeader : HEADERS_IP) {
			String ipHeaderValue=httpRequest.getHeader(ipHeader);
			if(TStringUtil.isValid(ipHeaderValue)) {
				return ipHeaderValue;
			}
		}
		return null;
	}
	public static String getRemoteAddress(HttpServletRequest httpRequest) {
		try {
			String remoteAddressValue = getRedirectionRemoteAddress(httpRequest);

			if (!TStringUtil.hasText(remoteAddressValue)) {
				remoteAddressValue = httpRequest.getRemoteAddr();
			}

			return remoteAddressValue;
		}catch (Exception e) {
			return "none";
		}

	}

	public static String getSystemHostName() {
		String hostName = "unknown";
		try {
			hostName = InetAddress.getLocalHost().getHostName();
		} catch (UnknownHostException e) {
			//TODO exception
		}
		return hostName;
	}

	public static String getBrowser(HttpServletRequest httpRequest) {
		try {
			String browser = httpRequest.getHeader("user-agent");
			return getBrowser(browser);
		}catch (Exception e) {
			return "none";
		}


	}

	public static String getBrowser(String userAgent) {
		String browserName = "unknown";
		String browserVer = "0";

		if (!TStringUtil.hasText(userAgent)) {
			return browserName + "-" + browserVer;
		}

		if (userAgent.contains("Chrome")) { // checking if Chrome
			String substring = userAgent.substring(userAgent.indexOf("Chrome")).split(" ")[0];
			browserName = substring.split("/")[0];
			browserVer = substring.split("/")[1];
		} else if (userAgent.contains("Firefox")) { // Checking if Firefox
			String substring = userAgent.substring(userAgent.indexOf("Firefox")).split(" ")[0];
			browserName = substring.split("/")[0];
			browserVer = substring.split("/")[1];
		} else if (userAgent.contains("MSIE")) { // Checking if Internet //
			// Explorer
			String substring = userAgent.substring(userAgent.indexOf("MSIE")).split(";")[0];
			browserName = substring;

			browserVer = substring.split(" ")[1];
		} else if (userAgent.contains("rv")) { // checking if Internet Explorer
			String substring = userAgent.substring(userAgent.indexOf("rv"), userAgent.indexOf(')'));
			browserName = "IE";
			browserVer = substring.split(":")[1];
		} else {
			return userAgent;
		}
		return browserName + "-" + browserVer;
	}

}
