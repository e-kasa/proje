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
public class AuthenticationRequest extends DtoBaseModel {

	private static final long serialVersionUID = 1L;

	private String username;

	private String password;


}
