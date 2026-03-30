package com.towpen.base.internalization;

import com.towpen.base.enums.model.LanguageType;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.util.EnumMap;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class AbstractMessageManager {
	private Map<String, Map<LanguageType, String>> messagesMap;

	public AbstractMessageManager() {

		log.info("Abstract initialized");
		messagesMap = new HashMap<>();
	}

	private String getInternalNotExistMessage(String messageCode) {
		return String.format("?%s?", messageCode);
	}

	public String getMessageText(String messageCode, LanguageType languageType) {
		Map<LanguageType, String> languageMap = this.messagesMap.get(messageCode);
		if (languageMap == null) {
			return getInternalNotExistMessage(messageCode);
		}
		String label = languageMap.get(languageType);
		return label == null ? getInternalNotExistMessage(messageCode) : label;
	}

	public void add(String code, LanguageType language, String label) {
		if (StringUtils.hasText(code) && language != null && StringUtils.hasText(label)) {
			if (this.messagesMap.containsKey(code)) {
				Map<LanguageType, String> languageMap = this.messagesMap.get(code);
				languageMap.put(language, label);
			} else {
				EnumMap<LanguageType, String> languageMap = new EnumMap<>(LanguageType.class);
				languageMap.put(language, label);
				this.messagesMap.put(code, languageMap);
			}

		}
	}
}
