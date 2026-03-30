package com.towpen.base.internalization;

import java.text.MessageFormat;
import java.util.List;
import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.models.TMessageBundleValue;
import com.towpen.base.exceptions.models.TMessageStaticValue;
import com.towpen.base.restservice.model.TMessageBaseValue;
import com.towpen.base.restservice.model.TOpenMessage;
import com.towpen.base.restservice.model.ext.BundleValue;
import com.towpen.base.restservice.model.ext.MessageValue;
import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
@Setter
@Getter
public class TOpenMessageManager {

	@Autowired
	private AbstractMessageManager messageManager;
    @Autowired
	private AbstractMessageManager bundleManager;




	public String getMessageText(String code, LanguageType languageType) {
		return messageManager.getMessageText(code, languageType);
	}
	public String getBundleText(String code,LanguageType languageType) {
		return bundleManager.getMessageText(code, languageType);
	}

	public String convertToText(TOpenMessage TOpenMessage,LanguageType languageType) {

		Object[] params = {};
		if (TOpenMessage.getParameters() != null && !TOpenMessage.getParameters().isEmpty()) {
			params = new Object[TOpenMessage.getParameters().size()];
			int index = 0;
			for (TMessageBaseValue parameterValue : TOpenMessage.getParameters()) {
				if (parameterValue.isBundleParameter()) {
					TMessageBundleValue bundledValue = (TMessageBundleValue) parameterValue;
					params[index] = getBundleText(bundledValue.getCode(),languageType);
				} else {
					TMessageStaticValue staticValue = (TMessageStaticValue) parameterValue;
					params[index] = staticValue.getValue();
				}
				index++;
			}
		}
		return getMessageText(TOpenMessage.getMessageCode(), languageType,params);
	}

	public String getMessageText(String code, LanguageType languageType, Object[]params) {
		String messageLongText=getMessageText(code,languageType);
		return MessageFormat.format(messageLongText, params);
	}
	public String getMessageText(TMessageType messageType,LanguageType languageType,Object[]params) {

		return getMessageText(messageType.getCode(), languageType,params);
	}


	public void addAllBundles(List<BundleValue> bundleValueList) {
		if (bundleValueList != null && !bundleValueList.isEmpty()) {
			for (BundleValue bundleValue : bundleValueList) {
				bundleManager.add(bundleValue.getBundleCode(), LanguageType.TR, bundleValue.getBundleMessageTr());
				bundleManager.add(bundleValue.getBundleCode(), LanguageType.EN, bundleValue.getBundleMessageEn());
			}
		}
	}

	public void addAllMessages(List<MessageValue> messageValueList) {
		if (messageValueList != null && !messageValueList.isEmpty()) {
			for (MessageValue messageValue : messageValueList) {
				messageManager.add(messageValue.getMessageCode(), LanguageType.TR, messageValue.getMessageTr());
				messageManager.add(messageValue.getMessageCode(), LanguageType.EN, messageValue.getMessageEn());
			}
		}
	}

}
