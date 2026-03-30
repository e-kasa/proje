package com.towpen.base.exceptions;

import com.towpen.base.restservice.model.TOpenMessage;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class TOpenException extends RuntimeException{

	private static final long serialVersionUID = 1L;
	private final transient List<TOpenMessage> messages;

	public TOpenException() {
		this.messages=new ArrayList<>();
	}
	public TOpenException(TOpenMessage ...jSureMessages ) {
		this();
		if(jSureMessages!=null && jSureMessages.length>0) {
			addAllMessage(Arrays.asList(jSureMessages));
		}
	}

	public void addMessage(TOpenMessage jsureMessage ) {
		this.messages.add(jsureMessage);
	}
	public void addAllMessage(List<TOpenMessage> jsureMessages ) {
		if(jsureMessages!=null && !jsureMessages.isEmpty()) {
			this.messages.addAll(jsureMessages);
		}

	}



	public void checkError() {
		if(!this.messages.isEmpty()) {
			throw this;
		}
	}
	public List<TOpenMessage> getMessages() {
		return messages;
	}
}
