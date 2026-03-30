package com.towpen.base.restservice.model;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class EnumValue extends DtoBaseModel{
	private static final long serialVersionUID = 1L;

	private String label;

	private String value;

	private String type;
}
