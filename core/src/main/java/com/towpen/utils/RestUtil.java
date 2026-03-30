package com.towpen.utils;
import com.towpen.base.security.ISessionInstanceService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Scope;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.http.MediaType;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.context.WebApplicationContext;

import java.util.ArrayList;
import java.util.List;
@Component
@Scope(value = WebApplicationContext.SCOPE_REQUEST, proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RestUtil {
	@Autowired
	private HttpServletRequest servletRequest;

	@Autowired
	private ISessionInstanceService sessionInstanceService;

	public RestTemplate createRestTemplate() {

		List<ClientHttpRequestInterceptor> interceptors = new ArrayList<>();

		interceptors.add(new HeaderRequestInterceptor("Accept", MediaType.APPLICATION_JSON_VALUE));

		interceptors.add(new HeaderRequestInterceptor("X-User-Info", servletRequest.getHeader("X-User-Info")));

		RestTemplate restTemplate = new RestTemplate();

		restTemplate.setInterceptors(interceptors);

		return restTemplate;

	}
}
