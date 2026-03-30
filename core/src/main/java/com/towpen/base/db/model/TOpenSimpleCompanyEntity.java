package com.towpen.base.db.model;

import com.towpen.base.db.model.comment.DBComments;
import com.towpen.base.hibernate.CompanyFilterStatics;
import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;
import org.hibernate.annotations.Filter;
import org.hibernate.annotations.FilterDef;
import org.hibernate.annotations.ParamDef;

@Getter
@Setter
@MappedSuperclass
@FilterDef(name = CompanyFilterStatics.FILTER_COMPANY, parameters = { @ParamDef(name = "cpCode", type = String.class) }, defaultCondition = "( company_code in( :cpCode) )")
@Filter(name =CompanyFilterStatics.FILTER_COMPANY, condition = "(  company_code   in(:cpCode))")
public class TOpenSimpleCompanyEntity extends TOpenSimpleDbEntity {
	private static final long serialVersionUID = 1L;

	@Comment(DBComments.Fields.SharedFields.FIELD_SHARED_COMPANY_CODE)
	@Column(name = "company_code", nullable = false,updatable = false,length = 8)
	protected String companyCode;
}
