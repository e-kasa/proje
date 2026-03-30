package com.towpen.base.restservice.model;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DtoEntityModel extends DtoBaseModel {

	private static final long serialVersionUID = 1L;

	private  String id;

	private String companyCode;

	protected Date createTime;

	protected Date lastModifiedTime;

	protected String createUser;

	protected String updateUser;
}
