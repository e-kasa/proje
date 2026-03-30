package com.towpen.base.annotations.process;

import com.towpen.base.annotations.definitions.EnumConverter;
import com.towpen.base.db.models.BaseDbEntity;
import com.towpen.base.enums.model.IEnumBundleBase;
import com.towpen.base.restservice.model.DtoBaseModel;
import com.towpen.base.restservice.model.EnumValue;
import com.towpen.base.security.ISessionInstanceService;
import com.towpen.utils.TStringUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.ReflectionUtils;
import org.springframework.stereotype.Component;

import org.springframework.data.util.ReflectionUtils.AnnotationFieldFilter;

import java.lang.reflect.Field;

@Component
public class EnumAnnotationFieldFilter {

	private AnnotationFieldFilter filter;
	@Autowired
	private EnumManager enumManager;
	@Autowired
	private ISessionInstanceService sessionInstanceService;

	public EnumAnnotationFieldFilter() {
		filter = new AnnotationFieldFilter(EnumConverter.class);
	}



	public <D extends DtoBaseModel, T extends BaseDbEntity> void processEnumFields(D dtoObject, T daoObject) {
		ReflectionUtils.doWithFields(dtoObject.getClass(), new ReflectionUtils.FieldCallback() {
			public void doWith(Field field) throws IllegalArgumentException, IllegalAccessException {
				ReflectionUtils.makeAccessible(field);
				EnumConverter[] enumAnnosArr = field.getAnnotationsByType(EnumConverter.class);
				if (enumAnnosArr != null && enumAnnosArr.length == 1) {
					EnumConverter conveterAnno = enumAnnosArr[0];
					String dbModelFieldName = conveterAnno.fieldName();
					if (TStringUtil.hasText(dbModelFieldName)) {
						Field dbModelField = ReflectionUtils.findField(daoObject.getClass(), dbModelFieldName);
						if (dbModelField != null) {
							ReflectionUtils.makeAccessible(dbModelField);
							EnumValue enumObject = enumManager.toEnumValue((IEnumBundleBase) dbModelField.get(daoObject),sessionInstanceService.getLanguage());
							ReflectionUtils.setField(field, dtoObject, enumObject);
						}

					}
				}
			}
		}, filter);
	}
}
