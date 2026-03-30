package com.towpen.base.generic.models;

import lombok.*;

import java.io.Serializable;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(includeFieldNames = true)
public class NameValuePair implements Serializable {
	private static final long serialVersionUID = 1L;
	private String name;
	private String value;
}
