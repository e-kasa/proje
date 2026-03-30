package com.towpen.base.restservice.model;

import java.util.Date;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonInclude.Include;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class TApiError {
	private String system;

	private Date errorTime;

	private String path;

	private TApiErrorType errorType;

	private String errorId;

	private List<TApiMessage> messages;

	private String errorDetail;

	public TApiError() {
		super();
	}
}
