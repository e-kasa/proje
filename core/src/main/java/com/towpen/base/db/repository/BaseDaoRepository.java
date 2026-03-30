package com.towpen.base.db.repository;

import com.towpen.base.db.model.TOpenDbEntity;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.PagingAndSortingRepository;
import org.springframework.stereotype.Repository;

public interface BaseDaoRepository<T extends TOpenDbEntity>extends PagingAndSortingRepository<T, String>, CrudRepository<T,String> {
}
