package com.towpen.base.exceptions;

public class TOpenRuntimeException extends RuntimeException{
	private static final long serialVersionUID = 1L;

	public TOpenRuntimeException(Throwable e ) {
		super(e);
	}
}
