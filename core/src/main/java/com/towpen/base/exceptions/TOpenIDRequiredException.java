package com.towpen.base.exceptions;

import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.models.TMessageFactory;
import com.towpen.base.restservice.model.TOpenMessage;

public final class TOpenIDRequiredException extends TOpenException{
	public  static final TOpenMessage ID_REQUIRED_EXCEPTION=new TOpenMessage(TMessageType.FIELD_IS_REQUIRED_1001, TMessageFactory.ofStatic("ID"));
	private static final long serialVersionUID = 1L;


	public TOpenIDRequiredException() {
		super(ID_REQUIRED_EXCEPTION);
	}
}
