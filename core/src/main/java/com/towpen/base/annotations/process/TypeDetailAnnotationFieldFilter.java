package com.towpen.base.annotations.process;

import com.towpen.base.annotations.definitions.TypeDetailConverter;
import com.towpen.base.db.models.BaseDbEntity;

import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.generic.models.NameValuePair;
import com.towpen.utils.TStringUtil;
import org.hibernate.Hibernate;
import org.springframework.util.ReflectionUtils;
import com.towpen.base.restservice.model.DtoBaseModel;
import com.towpen.base.security.ISessionInstanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import org.springframework.data.util.ReflectionUtils.AnnotationFieldFilter;

import java.lang.reflect.Field;

@Component
public class TypeDetailAnnotationFieldFilter {
	private AnnotationFieldFilter filter;

	@Autowired
	private ISessionInstanceService sessionInstanceService;

	public TypeDetailAnnotationFieldFilter() {
		filter = new AnnotationFieldFilter(TypeDetailConverter.class);
	}

	public <D extends DtoBaseModel, T extends BaseDbEntity> void processEnumFields(D dtoObject, T daoObject) {
		ReflectionUtils.doWithFields(dtoObject.getClass(), field -> processField(dtoObject, daoObject, field), filter);
	}

	private <D extends DtoBaseModel, T extends BaseDbEntity> void processField(D dtoObject, T daoObject, Field field) throws IllegalAccessException {
		ReflectionUtils.makeAccessible(field);
		TypeDetailConverter[] typeDetailAnnosArr = field.getAnnotationsByType(TypeDetailConverter.class);
		if (typeDetailAnnosArr != null && typeDetailAnnosArr.length == 1) {
			TypeDetailConverter converterTypeDetail = typeDetailAnnosArr[0];
			String dbModelFieldName = converterTypeDetail.fieldName();
			if (TStringUtil.hasText(dbModelFieldName)) {
				processDbModelField(dtoObject, daoObject, field, dbModelFieldName);
			}
		}
	}

	private <D extends DtoBaseModel, T extends BaseDbEntity> void processDbModelField(D dtoObject, T daoObject, Field field, String dbModelFieldName) throws IllegalAccessException {
		Field dbModelField = ReflectionUtils.findField(daoObject.getClass(), dbModelFieldName);
		if (dbModelField != null) {
			ReflectionUtils.makeAccessible(dbModelField);
			Object typeDetail = dbModelField.get(daoObject);
			if (typeDetail != null && Hibernate.isInitialized(typeDetail)) {
				Field valueField = ReflectionUtils.findField(typeDetail.getClass(), "id");
				Field textField = ReflectionUtils.findField(typeDetail.getClass(), sessionInstanceService.getLanguage() == LanguageType.TR ? "labelTr" : "labelEn");
				if (valueField != null && textField != null) {
					ReflectionUtils.makeAccessible(valueField);
					ReflectionUtils.makeAccessible(textField);
					String typeDetailID = (String) valueField.get(typeDetail);
					String label = (String) textField.get(typeDetail);
					NameValuePair valuePair = new NameValuePair(typeDetailID, label);
					ReflectionUtils.setField(field, dtoObject, valuePair);
				}
			}
		}
	}
}
