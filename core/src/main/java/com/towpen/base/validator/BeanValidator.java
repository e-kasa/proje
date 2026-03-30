package com.towpen.base.validator;

import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.exceptions.rest.ApiErrorBeanController;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import jakarta.validation.groups.Default;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Component
public class BeanValidator implements IBeanValidator{
	@Autowired
	private ApiErrorBeanController apiBeanController;

@Autowired
	private Validator validator;

	@Override
	public List<TOpenMessage> validate(Object obj,boolean throwException) {
		return validate("", obj, throwException);

	}

	@Override
	public List<TOpenMessage> validate(String prefix, Object obj, boolean throwException) {

		return validate("", obj, throwException, Default.class);

	}
	@Override
	public List<TOpenMessage> validate(String prefix, Object obj, boolean throwException,Class<?>validatorClass) {
		List<TOpenMessage> errors =new ArrayList<>();
		Set<ConstraintViolation<Object>> validationMessages = validator.validate(obj, validatorClass);
		if (validationMessages != null && !validationMessages.isEmpty()) {
			errors = apiBeanController.createModel(validationMessages);
			if (throwException) {
				TOpenException ex=new TOpenException();
				ex.addAllMessage(errors);
				throw ex;
			}
		}
		return errors;

	}



}
