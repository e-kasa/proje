package com.towpen.base.db.model;

import com.towpen.base.db.model.comment.DBComments;
import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Comment;

import java.util.Date;

@Getter
@Setter
@MappedSuperclass
public abstract class TOpenSimpleDbEntity extends TOpenDbEntity {

	private static final long serialVersionUID = 1L;

	@Comment(DBComments.Fields.SharedFields.FIELD_SHARED_CREATE_TIME)
	@Temporal(TemporalType.TIMESTAMP)
	@Column(nullable = false, name = "create_time",updatable = false)
	protected Date createTime;

	@Comment(DBComments.Fields.SharedFields.FIELD_SHARED_LAST_MODIFIED_TIME)
	@Temporal(TemporalType.TIMESTAMP)
	@Column(nullable = true, name = "last_modified_time",insertable = false)
	protected Date lastModifiedTime;

	@Comment(DBComments.Fields.SharedFields.FIELD_SHARED_CREATE_USER)
	@Column(name = "create_user", nullable = false,length = 32,updatable = false)
	protected String createUser;

	@Comment(DBComments.Fields.SharedFields.FIELD_SHARED_LAST_MODIFIED_USER)
	@Column(name = "update_user", nullable = true,length = 32,insertable = false)
	protected String updateUser;
}
