package com.towpen.base.generic.models;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.*;

@Getter
@Setter
@Builder()
@AllArgsConstructor
@NoArgsConstructor
public class CoxNameValuePair extends DtoBaseModel {
	private static final long serialVersionUID = 1L;

	private String id;
	private String code;
	private String name;
}
