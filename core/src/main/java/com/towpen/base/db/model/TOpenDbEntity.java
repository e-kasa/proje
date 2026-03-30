package com.towpen.base.db.model;

import com.towpen.base.db.models.BaseDbEntity;
import com.towpen.base.generic.models.CoxNameValuePair;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.hibernate.annotations.GenericGenerator;

@Getter
@Setter
@MappedSuperclass
public abstract class TOpenDbEntity extends BaseDbEntity {
	@Id
	@GeneratedValue(generator = "UUID")
	@GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
	protected String id;
	public CoxNameValuePair toNameValuePair() {
		CoxNameValuePair pair=new CoxNameValuePair();
		pair.setId(getId());
		return pair;
	}

	@Override
	public boolean equals(Object obj) {
		TOpenDbEntity checkObj=(TOpenDbEntity)obj;
		return new EqualsBuilder().append(getId(),checkObj.getId()).isEquals();
	}
}
