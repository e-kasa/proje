package com.towpen.base.validator;

import com.towpen.base.restservice.model.TOpenMessage;

import java.util.List;

public interface IBeanValidator {
	List<TOpenMessage> validate( Object obj ,boolean throwException);

	List<TOpenMessage>  validate(String prefix, Object obj, boolean throwException);

	List<TOpenMessage> validate(String prefix, Object obj, boolean throwException,Class<?>validatorClass);

}
