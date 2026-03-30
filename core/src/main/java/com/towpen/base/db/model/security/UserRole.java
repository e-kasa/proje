package com.towpen.base.db.model.security;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import com.towpen.base.db.model.comment.DBComments;
import com.towpen.base.db.models.SimpleBaseDbEntitiy;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

@Getter
@Setter
@Entity
@Table(name = "user_role")
@Comment(DBComments.Tables.TABLE_USER_ROLE)
@NamedEntityGraph(name = "userRoleDetails", attributeNodes = { @NamedAttributeNode(value = "roleDef"), @NamedAttributeNode(value = "userDef") })
public class UserRole extends TOpenSimpleCompanyEntity {


	private static final long serialVersionUID = 8572212772160678327L;

	@Comment(DBComments.Fields.FIELD_USER_ROLE_ROLE_DEF_ID)
	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	private RoleDef roleDef;

	@Comment(DBComments.Fields.FIELD_USER_ROLE_USER_DEF_ID)
	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	private UserDef userDef;

}
