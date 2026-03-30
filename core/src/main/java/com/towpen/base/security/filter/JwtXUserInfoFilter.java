package com.towpen.base.security.filter;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.json.JsonMapper;
import com.towpen.base.context.TOpenContext;
import com.towpen.base.context.TOpenContextHolder;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.rest.ApiErrorBeanController;
import com.towpen.base.restservice.model.RestRootEntity;
import com.towpen.base.restservice.model.TApiError;
import com.towpen.base.restservice.model.TOpenMessage;
import com.towpen.base.security.model.TOpenAuthenticationToken;
import com.towpen.base.security.model.TOpenSessionInstance;
import com.towpen.utils.TObjectUtils;
import com.towpen.utils.TStringUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.GenericFilterBean;

import java.io.IOException;
import java.io.Writer;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

public class JwtXUserInfoFilter extends GenericFilterBean {

	public static final String X_USER_INFO_HEADER = "X-User-Info";

	private static final String API_REQUEST_START = "/api";

	public static final String METHOD_AUTHENTICATE = "/authenticate";

	private ApiErrorBeanController apiBeanController;


	private ObjectMapper mapper;

	private JsonMapper jsonMapper;

	public JwtXUserInfoFilter(ApiErrorBeanController apiBeanController) {
		this.apiBeanController = apiBeanController;
		this.mapper = new ObjectMapper();
	}
	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
		HttpServletRequest httpRequest = asHttpRequest(request);
		HttpServletResponse httpResponse = asHttpResponse(response);
		String requestURL = httpRequest.getServletPath();
		httpRequest.setCharacterEncoding("UTF-8");
		httpResponse.setCharacterEncoding("UTF-8");
		try {
			TOpenSessionInstance xUserInfo = resolveXUserInfoAsObject(httpRequest);
			if(requestURL.startsWith(API_REQUEST_START) && !requestURL.equals("/api/rest/sso-log")) {
				if (xUserInfo == null) {
					prepareNoAccessError(httpResponse);
					return;
				}
				TOpenAuthenticationToken jsureToken = createAuthToken(xUserInfo, resolveToken(httpRequest));
				SecurityContextHolder.getContext().setAuthentication(jsureToken);
				httpResponse.addHeader(X_USER_INFO_HEADER, resolveXUserInfo(httpRequest));
				chain.doFilter(httpRequest, httpResponse);
			} else {
				chain.doFilter(httpRequest, httpResponse);
			}

		} catch (Exception e) {
			prepareError(httpResponse, e);

		}
	}


	private TOpenAuthenticationToken createAuthToken(TOpenSessionInstance xUserInfo, String token) {

		List<SimpleGrantedAuthority> springSecurityRoles = new ArrayList<>();
		List<String> roles = xUserInfo.getRoles();
		if (!TObjectUtils.isEmpty(roles)) {
			roles.forEach(userRole -> springSecurityRoles.add(new SimpleGrantedAuthority("ROLE_" + userRole)));
		}
		TOpenAuthenticationToken jSureAuthenticationToken =
				new TOpenAuthenticationToken(xUserInfo.getUserInformation().getUserId(), xUserInfo.getUserInformation().getUserName(), springSecurityRoles,token);
		jSureAuthenticationToken.setSessionInstance(xUserInfo);
		TOpenContext ctx = new TOpenContext();
		ctx.setCompanyCode(xUserInfo.getUserInformation().getSelectedCompanyCode());
		ctx.setDisableCompanyFilter(false);
		ctx.setUseInCompanyFilter(true);

		TOpenContextHolder.setContext(ctx);

		return jSureAuthenticationToken;

	}
	private String resolveXUserInfo(HttpServletRequest request) {

		return request.getHeader(X_USER_INFO_HEADER);
	}
	private TOpenSessionInstance resolveXUserInfoAsObject(HttpServletRequest request) throws JsonProcessingException {

		String xUserInfoHeader = resolveXUserInfo(request);
		if (TStringUtil.hasText(xUserInfoHeader)) {
    			xUserInfoHeader= URLDecoder.decode(xUserInfoHeader, Charset.forName("UTF-8"));
			return mapper.readValue(xUserInfoHeader, TOpenSessionInstance.class);

		}return null;
	}

	private String resolveToken(HttpServletRequest httpRequest) {
		String bearerToken = httpRequest.getHeader("Authorization");
		if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
			return bearerToken.substring(7, bearerToken.length());
		}
		return null;
	}

	private void prepareError(HttpServletResponse httpResponse, Exception e) {
		SecurityContextHolder.clearContext();
		TApiError errorModel = apiBeanController.createApiError();
		errorModel.setMessages(new ArrayList<>());
		errorModel.getMessages().add(apiBeanController.convertToApiMessage(new TOpenMessage(TMessageType.NOT_AUTHORIZED_1012)));
		httpResponse.setContentType("application/json");
		ObjectMapper objMapper = new ObjectMapper();
		RestRootEntity<Object> rootEntity = RestRootEntity.error(HttpServletResponse.SC_UNAUTHORIZED, errorModel);
		String apiErrorJSON;
		try {
			apiErrorJSON = objMapper.writeValueAsString(rootEntity);
			httpResponse.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
			Writer writer = httpResponse.getWriter();
			writer.write(apiErrorJSON);
			writer.flush();
			writer.close();
		} catch (Exception e2) {
			logger.error(e);
		}

	}

	private void prepareNoAccessError(HttpServletResponse httpResponse) {
		prepareError(httpResponse, null);

	}
	private HttpServletRequest asHttpRequest(ServletRequest request) {
		return (HttpServletRequest) request;
	}

	private HttpServletResponse asHttpResponse(ServletResponse response) {
		return (HttpServletResponse) response;
	}

}
