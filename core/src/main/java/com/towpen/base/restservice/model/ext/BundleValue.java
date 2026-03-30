package com.towpen.base.restservice.model.ext;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class BundleValue {
	private String bundleCode;

	private String bundleMessageTr;

	private String bundleMessageEn;
}
