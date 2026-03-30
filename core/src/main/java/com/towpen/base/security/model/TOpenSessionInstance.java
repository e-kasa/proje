package com.towpen.base.security.model;

import com.towpen.base.db.model.security.RoleDef;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class TOpenSessionInstance {
	private TOpenLoginUser userInformation;

	private List<String> roles;
}
