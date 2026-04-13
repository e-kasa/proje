package com.towpen.base.db.model.security;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import com.towpen.base.db.model.comment.DBComments;
import com.towpen.base.db.models.SimpleBaseDbEntitiy;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

@Getter
@Setter
@Entity
@Table(name = "role_def",
       uniqueConstraints = @UniqueConstraint(columnNames = {"company_code", "name"}))
@Comment(DBComments.Tables.TABLE_ROLE_DEF)
public class RoleDef extends TOpenSimpleCompanyEntity {


	@Column(name = "name", nullable = false, length = 255)
	private String name;

	@Column(name = "description", length = 255)
	private String description;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;

	@Column(name = "is_system_role", nullable = false)
	private Boolean isSystemRole;

	@Column(name = "code", nullable = true)
	private String code;
}
