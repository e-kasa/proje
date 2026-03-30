package com.towpen.base.db.models;

import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

@Getter
@Setter
@MappedSuperclass
public class BaseDbEntity implements Serializable {

	private static final long serialVersionUID = 1L;

}
