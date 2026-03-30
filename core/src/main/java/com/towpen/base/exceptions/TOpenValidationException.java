package com.towpen.base.exceptions;

import jakarta.validation.ConstraintDeclarationException;

public class TOpenValidationException extends ConstraintDeclarationException {
	private static final long serialVersionUID = 1L;

	public TOpenValidationException(String message) {
		super(message);
	}
}
