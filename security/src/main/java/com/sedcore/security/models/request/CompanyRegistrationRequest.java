package com.sedcore.security.models.request;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class CompanyRegistrationRequest extends DtoBaseModel {

	private static final long serialVersionUID = 1L;

	private String companyName;
	private String sectorType;
	private String taxNumber;
	private String taxOffice;
	private String userName;
	private String password;
	private String displayName;
	private String email;
}
