package com.towpen.base.context;

import lombok.*;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class TOpenContext {
	private String companyCode;
	private boolean disableCompanyFilter;
	private boolean useInCompanyFilter;

	public TOpenContext(boolean disableCompanyFilter,boolean useInCompanyFilter , String companyCode){
		this.disableCompanyFilter=disableCompanyFilter;
		this.useInCompanyFilter=useInCompanyFilter;
		this.companyCode=companyCode;
	}
}
