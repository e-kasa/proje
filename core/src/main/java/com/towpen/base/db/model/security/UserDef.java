package com.towpen.base.db.model.security;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.db.model.comment.DBComments;
import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.UserDefGenericIdType;
import com.towpen.base.enums.model.UserType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

@Entity
@Table(uniqueConstraints = { @UniqueConstraint(columnNames = { "user_name" }) })
@Getter
@Setter
@Comment(DBComments.Tables.TABLE_USER_DEF)
public class UserDef extends TOpenSimpleCompanyEntity {

	private static final long serialVersionUID = 1L;

	@Column(name = "user_name", length = 40, unique = true, nullable = false)
	private String userName;

	@Column(name = "user_display_name", length = 200, nullable = false)
	private String userDisplayName;

	@Enumerated(EnumType.STRING)
	@Column(name = "language_val", nullable = false, length = 3)
	private LanguageType languageVal;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;

	@Enumerated(EnumType.STRING)
	@Column(name = "user_type", nullable = true)
	private UserType userType;

	@Column(name = "generic_identifier", nullable = true)
	private String genericIdentifier;

	@Comment(DBComments.Fields.FIELDS_USER_DEF_GENERIC_IDENTIFIER_TYPE)
	@Enumerated(EnumType.STRING)
	@Column(name = "user_def_generic_id_type", nullable = true)
	private UserDefGenericIdType userDefGenericIdType;

	/** Kullanıcının atandığı mağaza ID (kasiyerler için) — null ise tüm mağazalara erişim */
	@Comment("Kullanıcının atandığı mağaza — null ise tüm mağazalara erişim (admin/depo)")
	@Column(name = "store_id", nullable = true, length = 50)
	private String storeId;

}
