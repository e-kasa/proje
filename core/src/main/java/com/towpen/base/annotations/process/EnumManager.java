package com.towpen.base.annotations.process;

import com.towpen.base.enums.model.EnumMatcher;
import com.towpen.base.enums.model.IEnumBundleBase;
import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.SortType;
import com.towpen.base.generic.models.NameValuePair;
import com.towpen.base.internalization.TOpenMessageManager;
import com.towpen.base.restservice.model.EnumValue;
import com.towpen.utils.TObjectUtils;
import com.towpen.utils.sort.SortUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Component
public class EnumManager {
	@Autowired
	private TOpenMessageManager messageManager;




	public EnumValue toEnumValue(IEnumBundleBase enumBase,LanguageType language) {
		if(enumBase != null) {
			EnumValue typeValue=new EnumValue();
			String label = messageManager.getBundleText(enumBase.getBundleCode(),language);
			typeValue.setLabel(label);
			typeValue.setValue(enumBase.getValue());
			typeValue.setType(enumBase.getClass().getSimpleName());

			return typeValue;

		}
		return null;
	}

	public List<EnumValue> toEnumValues(List<IEnumBundleBase> enumBaseList,LanguageType language) {
		List<EnumValue> enumValueList=new ArrayList<>();
		if(!TObjectUtils.isEmpty(enumBaseList)) {
			enumBaseList.forEach(eValue->enumValueList.add(toEnumValue(eValue, language)));

		}
		return enumValueList;
	}

	public List<IEnumBundleBase> getEnumValues(String typeMasterShortCode) {
		Class<?> iEnumBundleBase = EnumMatcher.getEnumClass(typeMasterShortCode);
		IEnumBundleBase []arrValues=(IEnumBundleBase[]) iEnumBundleBase.getEnumConstants();
		return Arrays.asList(arrValues);

	}

	public List<NameValuePair> enumValuesToNameValuePairs(String typeMasterShortCode, LanguageType language, SortType sortType) {

		return toNameValuePairs(getEnumValues(typeMasterShortCode), language,sortType);

	}
	public List<NameValuePair> toNameValuePairs(List<IEnumBundleBase> enumBundleBases,LanguageType language,SortType sortType) {
		List<NameValuePair> nameValuePairs=new ArrayList<>();
		for (IEnumBundleBase enumBundleBase : enumBundleBases) {
			EnumValue enumValue=toEnumValue(enumBundleBase, language);
			nameValuePairs.add(new NameValuePair(enumValue.getLabel(), enumValue.getValue()));
		}
		if(sortType!=null) {
			boolean asc=true;
			if(SortType.DESCENDING==sortType) {
				asc=false;
			}
			SortUtil.sortThis(nameValuePairs, "name", asc);
		}

		return nameValuePairs;
	}

}
