package com.towpen.base.db.model.security;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.db.model.comment.DBComments;
import com.towpen.base.enums.model.AccessType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

import java.util.Date;

@Entity
@Getter
@Setter
@Table(uniqueConstraints = {@UniqueConstraint(columnNames = {"user_def_id","company_code"})})
@Comment(DBComments.Tables.TABLE_USER_DEF_ACCESS)
@NamedEntityGraph(name = "user-def-access-entity", attributeNodes = {@NamedAttributeNode(value = "userDef") })
public class UserDefAccess extends TOpenSimpleCompanyEntity {
	private static final long serialVersionUID = -2813339787601688741L;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_USER_DEF_ID)
	@ManyToOne(optional = false,fetch = FetchType.LAZY)
	private UserDef userDef;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_CAN_LOGIN)
	@Column(name = "can_login",nullable = false)
	private Boolean canLogin;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_IS_FORCE_PASSWORD_CHANGE)
	@Column(name = "is_force_password_change", nullable = false)
	private Boolean isForcePasswordChange;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_SALT_KEY)
	@Column(name = "salt_key", nullable = true,length = 100)
	private String saltKey;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_PASSWORD_HASH)
	@Column(name = "password_hash", nullable = true,length = 400)
	private String passwordHash;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_LAST_CHANGE_TIME)
	@Temporal(TemporalType.TIMESTAMP)
	@Column(name = "last_change_time", nullable = true)
	private Date lastChangeTime;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_HAS_IP_RESTRICTION)
	@Column(name = "has_ip_restriction" , nullable = false)
	private Boolean hasIpRestriction;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_IP_RESTRICTION)
	@Column(name = "ip_restriction" , nullable = false)
	private String ipRestriction;

	@Comment(DBComments.Fields.FIELD_USER_DEF_ACCESS_ACCESS_TYPE)
	@Enumerated(EnumType.STRING)
	@Column(name = "access_type" , nullable = false)
	private AccessType accessType;
}
