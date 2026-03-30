package com.towpen.base.restservice.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.towpen.utils.ReflectionUtil;
import com.towpen.utils.TObjectUtils;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class RestRootEntity<T> {

	private static final Integer UUID_REPEAT_COUNT = 2;


	private Integer status;

	private T payload;

	private TApiError exception;

	private String traceId;

	private List<TApiMessage> messages;

	private static <T> RestRootEntity<T> createResponseWithTraceId() {
		RestRootEntity<T> obj = new RestRootEntity<>();
		obj.setMessages(new ArrayList<>());
		obj.setTraceId(createTraceId());
		return obj;

	}
	public static String createTraceId() {
		return createUUID(UUID_REPEAT_COUNT);
	}

	private static String createUUID(int count) {
		StringBuilder buffer = new StringBuilder();
		for (int i = 0; i < count; i++) {
			buffer.append(createUUID());
		}
		return buffer.toString();
	}

	private static String createUUID() {
		return UUID.randomUUID().toString().replace("-", "");
	}


	private static <T> RestRootEntity<T> build(T payload, Integer status, TApiError exception) {
		RestRootEntity<T> obj = createResponseWithTraceId();
		obj.setStatus(status);
		obj.setPayload(payload);
		if(ReflectionUtil.isSuperClass(payload, DtoBaseModel.class)) {
			DtoBaseModel dtoBaseModel=(DtoBaseModel) payload;
			if(!TObjectUtils.isEmpty(dtoBaseModel.getMessages())) {
				obj.setMessages(dtoBaseModel.getMessages());
			}
		}
		obj.setException(exception);
		return obj;
	}

	public static <T> RestRootEntity<T> ok(T payload) {
		return build(payload, 200, null);

	}

	public static <T> RestRootEntity<T> error(Integer status, TApiError exception) {
		return build(null, status, exception);

	}
}
