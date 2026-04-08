package com.towpen.base.exceptions.rest;

import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.enums.model.ValidationType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.exceptions.models.TMessageBundleValue;
import com.towpen.base.exceptions.models.TMessageStaticValue;
import com.towpen.base.internalization.TOpenMessageManager;
import com.towpen.base.restservice.model.*;
import com.towpen.base.security.ISessionInstanceService;
import com.towpen.utils.RandomUtil;
import com.towpen.utils.TDateUtils;
import com.towpen.utils.WebUtils;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import lombok.Generated;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.validation.FieldError;
import org.springframework.validation.ObjectError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.util.UrlPathHelper;

import java.util.*;

@Component
public class ApiErrorBeanController {
	@Generated
	private static final Logger log = LoggerFactory.getLogger(ApiErrorBeanController.class);
	@Autowired
	private HttpServletRequest request;

	@Autowired
	private ISessionInstanceService sessionInstanceService;

	private TMessageType unexpectedError = TMessageType.UNEXPECTED_ERROR_9999;

	private static final int ERROR_CODE_LENGTH = 5;

	private static final String ERROR_DATE_FORMAT = "yyMMddHHmmss";

	private String createErrorCode() {

		String dateFormat = TDateUtils.formatDate(ERROR_DATE_FORMAT, Calendar.getInstance().getTime());
		String randomErrorCode = RandomUtil.createRandomAlphanumeric(ERROR_CODE_LENGTH).toUpperCase(Locale.ENGLISH);
		return dateFormat + "-" + randomErrorCode;

	}

	@Autowired
	private TOpenMessageManager messageManager;

	public ApiErrorBeanController() {
		log.info("ApiErrorBeanController initialized");
	}

	public TApiError createApiError() {
		TApiError model = new TApiError();
		model.setSystem(WebUtils.getSystemHostName());
		model.setErrorTime(Calendar.getInstance().getTime());
		String resourcePath = new UrlPathHelper().getPathWithinApplication(this.request);
		model.setPath(resourcePath);
		return model;
	}

	public TApiError createApiError(TOpenException jsureException) {
		TApiError apiErrorModel = createApiError();
		apiErrorModel.setErrorType(TApiErrorType.BUSINESS);
		apiErrorModel.setMessages(convertToApiMessages(jsureException.getMessages()));
		return apiErrorModel;
	}

	public TApiError createApiError(String errorCode) {
		TApiError model = createApiError();
		TApiMessage singleRowMessage = new TApiMessage(errorCode, getBundleText(errorCode));
		model.setMessages(new ArrayList<>());
		model.getMessages().add(singleRowMessage);
		return model;
	}

	public TApiError createUnexpectedError() {
		TApiError model = createApiError();
		String systemErrorCode = createErrorCode();
		Object[] errorCodeArray = new Object[] { systemErrorCode };
		String errorMessage = getMessageText(unexpectedError.getCode(), errorCodeArray, getSelectedLanguage());
		TApiMessage singleRowMessage = new TApiMessage(unexpectedError.getCode(), errorMessage);
		model.setErrorId(systemErrorCode);
		model.setMessages(new ArrayList<>());
		model.getMessages().add(singleRowMessage);

		return model;
	}

	public TApiError createClientError(String errorMessage) {
		TApiError model = createApiError();
		String systemErrorCode = createErrorCode();
		TApiMessage singleRowMessage = new TApiMessage(unexpectedError.getCode(), errorMessage);
		model.setErrorId(systemErrorCode);
		model.setMessages(new ArrayList<>());
		model.getMessages().add(singleRowMessage);

		return model;
	}

	public String getMessageText(String errorCode) {
		return messageManager.getMessageText(errorCode, getSelectedLanguage());
	}

	public String getBundleText(String errorCode) {
		return messageManager.getBundleText(errorCode, getSelectedLanguage());
	}

	public LanguageType getSelectedLanguage() {
		try {
			return sessionInstanceService.getLanguage();
		} catch (Exception e) {
			return LanguageType.TR;
		}
	}

	public String getMessageText(String errorCode, Object[] params, LanguageType languageType) {
		return messageManager.getMessageText(errorCode, languageType, params);
	}

	public TApiMessage convertToApiMessage(TOpenMessage jsureMessage) {
		TApiMessage apiMessage = new TApiMessage();
		apiMessage.setCode(jsureMessage.getMessageCode());
		apiMessage.setMessage(convertToText(jsureMessage));
		return apiMessage;
	}

	public List<TApiMessage> convertToApiMessages(List<TOpenMessage> jsureMessages) {
		List<TApiMessage> apiMessages = new ArrayList<>();
		if (jsureMessages != null && !jsureMessages.isEmpty()) {
			for (TOpenMessage jsureMessage : jsureMessages) {
				apiMessages.add(convertToApiMessage(jsureMessage));
			}
		}
		return apiMessages;
	}

	public String convertToApiMessagesToText(List<TOpenMessage> jsureMessages) {
		StringBuilder builder = new StringBuilder();
		List<TApiMessage> errorMessages = convertToApiMessages(jsureMessages);
		for (TApiMessage TApiMessage : errorMessages) {
			builder.append("(");
			builder.append(TApiMessage.getCode());
			builder.append(")");
			builder.append(TApiMessage.getMessage());
			builder.append(" -");
		}
		return builder.toString();
	}

	public String convertToText(TOpenMessage tOpenMessageMessage) {

		Object[] params = {};
		if (tOpenMessageMessage.getParameters() != null && !tOpenMessageMessage.getParameters().isEmpty()) {
			params = new Object[tOpenMessageMessage.getParameters().size()];
			int index = 0;
			for (TMessageBaseValue parameterValue : tOpenMessageMessage.getParameters()) {
				if (parameterValue.isBundleParameter()) {
					TMessageBundleValue bundledValue = (TMessageBundleValue) parameterValue;
					params[index] = getBundleText(bundledValue.getCode());
				} else {
					TMessageStaticValue staticValue = (TMessageStaticValue) parameterValue;
					params[index] = staticValue.getValue();
				}
				index++;
			}
		}
		return getMessageText(tOpenMessageMessage.getMessageCode(), params, sessionInstanceService.getLanguage());

	}

	public TApiError createModel(MethodArgumentNotValidException e) {
		TApiError model = createApiError();

		List<TApiMessage> apiMessages = new ArrayList<>();
		List<FieldError> fieldErrors = e.getFieldErrors();
		for (FieldError fieldError : fieldErrors) {
			String errorCode = fieldError.getCode();
			String defaultMessage = fieldError.getDefaultMessage();
			TOpenMessage message = prepareFieldError(errorCode, defaultMessage, fieldError.getArguments());
			apiMessages.add(convertToApiMessage(message));
		}

		if (apiMessages.isEmpty()) {
			apiMessages = e.getAllErrors().stream().map(this::prepareApiError).toList();
		}

		model.setMessages(apiMessages);

		return model;
	}

	public List<TOpenMessage> createModel(Set<ConstraintViolation<Object>> validationErrors) {
		List<TOpenMessage> messages = new ArrayList<>();

		for (ConstraintViolation<Object> constraintViolation : validationErrors) {
			TOpenMessage jsureMessage = prepareFieldError(constraintViolation.getConstraintDescriptor().getAnnotation().annotationType().getSimpleName(), constraintViolation.getMessageTemplate(), constraintViolation.getExecutableParameters());

			messages.add(jsureMessage);
		}

		return messages;
	}

	public TApiMessage prepareApiError(ObjectError e) {
		return convertToApiMessage(prepareError(e));
	}

	public TOpenMessage prepareError(ObjectError e) {
		ValidationType validationType = ValidationType.getValidationType(e.getCode());
		if (Objects.isNull(validationType)) {
			TOpenMessage msg = new TOpenMessage(TMessageType.VALIDATION_ERROR);
			msg.addStaticValue(e.getDefaultMessage());

			return msg;
		}

		return prepareFieldError(e.getCode(), e.getDefaultMessage(), e.getArguments());
	}

	public TOpenMessage prepareFieldError(String errorCode, String defaultMessage, Object[] arguments) {
		ValidationType validationType = ValidationType.getValidationType(errorCode);
		TOpenMessage exceptionModel = new TOpenMessage(TMessageType.getMessageType(validationType.getBundleCode()));
		exceptionModel.addBundleValue(defaultMessage);
		if (validationType == ValidationType.SIZE) {
			Integer minValue = (Integer) arguments[2];
			Integer maxValue = (Integer) arguments[1];
			exceptionModel.addStaticValue(minValue);
			exceptionModel.addStaticValue(maxValue);
		} else if (validationType == ValidationType.MIN || validationType == ValidationType.MAX) {
			Long minOrMaxValue = (Long) arguments[1];
			exceptionModel.addStaticValue(minOrMaxValue);
		}
		return exceptionModel;
	}
}
