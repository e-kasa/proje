package com.towpen.base.restservice.model;

import com.towpen.utils.TStringUtil;

import java.util.HashMap;

public class DtoExternalAttrs {
	private HashMap<String,String> values;

	public DtoExternalAttrs(){
		this.values=new HashMap<>();
	}

	public void addAttr(String key,String value){
		if(!TStringUtil.isNullOrBlank(key)&&!TStringUtil.isNullOrBlank(value)){
			values.put(key,value);
		}
	}
}
