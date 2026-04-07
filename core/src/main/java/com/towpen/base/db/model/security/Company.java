package com.towpen.base.db.model.security;

import com.towpen.base.db.model.TOpenDbEntity;
import com.towpen.base.db.model.comment.DBComments;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

@Entity
@Getter
@Setter
@Comment(DBComments.Tables.TABLE_COMPANY)
public class Company extends TOpenDbEntity {
	private static final long serialVersionUID = 2614036485265711893L;

	@Comment(DBComments.Fields.FIELD_COMPANY_COMPANY_CODE)
	@Column(name = "company_code",unique = true,nullable = false,length = 8)
	private String companyCode;

	@Comment(DBComments.Fields.FIELD_COMPANY_COMPANY_NAME)
	@Column(name = "company_name",nullable = false,length = 200)
	private String companyName;

	@Comment(DBComments.Fields.FIELD_COMPANY_MINI_LOGO_ID)
	@Column(name = "mini_logo_id",nullable = true,length = 50)
	private String miniLogoId;

	@Comment(DBComments.Fields.FIELD_COMPANY_LOGO_ID)
	@Column(name = "logo_id",nullable = true,length = 50)
	private String logoId;

	@Comment(DBComments.Fields.FIELD_COMPANY_IS_MAIN_COMPANY)
	@Column(name = "is_main_company",nullable = true)
	private Boolean isMainCompany;

	@Comment(DBComments.Fields.FIELD_COMPANY_TAX_NUMBER)
	@Column(name = "TAX_NUMBER")
	private String taxNumber;

	@Comment(DBComments.Fields.FIELD_COMPANY_TAX_OFFICE)
	@Column(name = "TAX_OFFICE")
	private String taxOffice;

	/**
	 * Firmanın web sitesi domain'i.
	 * API Gateway bu alan üzerinden hangi firmadan istek geldiğini belirler.
	 * Örnek: "www.bertspot.com", "www.sedcore.com"
	 */
	@Comment("Firmanın domain adresi – gateway domain çözümlemesi için kullanılır")
	@Column(name = "domain", nullable = true, unique = true, length = 255)
	private String domain;

	/**
	 * Şirketin faaliyet sektörü.
	 * Flutter uygulaması UI'yi bu değere göre uyarlar.
	 * Değerler: AUTO_PARTS, GENERAL, TECHNOLOGY, FOOTWEAR
	 */
	@Comment("Şirket sektörü – Flutter UI sektör konfigürasyonu için kullanılır")
	@Column(name = "sector_type", nullable = true, length = 20)
	private String sectorType;
}
