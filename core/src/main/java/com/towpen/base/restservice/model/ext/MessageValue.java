package com.towpen.base.restservice.model.ext;

import com.towpen.base.restservice.model.DtoEntityModel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class MessageValue  extends DtoEntityModel {
	private String messageCode;

	private String messageTr;

	private String messageEn;
}
