package com.towpen.base.security.model;

import com.towpen.base.generic.models.TOpenNameValuePair;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class TOpenUserRoleAuth {
	private String userName;

	private List<TOpenAuth> authorizations;
	private List<TOpenUserRestriction> restrictions;



	@Getter
	@Setter
	public static class TOpenAuth extends TOpenNameValuePair {

	}


	public static class TOpenRole{

	}
}
