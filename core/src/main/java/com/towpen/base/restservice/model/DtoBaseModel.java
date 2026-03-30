package com.towpen.base.restservice.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DtoBaseModel implements Serializable {
	private static final long serialVersionUID = 1L;

	@JsonIgnore
	private List<TApiMessage> messages;
	private DtoExternalAttrs attrs;
	public DtoBaseModel(){
		this.messages = new ArrayList<>();
	}
	public void addMessage(TApiMessage message){
		this.messages.add(message);
	}
}
