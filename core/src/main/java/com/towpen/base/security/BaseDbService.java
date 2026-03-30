package com.towpen.base.security;

import com.towpen.base.db.model.TOpenSimpleDbEntity;
import com.towpen.base.db.models.BaseDbEntity;
import com.towpen.base.db.sequence.SequenceType;
import com.towpen.base.generic.models.CoxNameValuePair;
import com.towpen.base.restservice.model.DtoBaseModel;
import com.towpen.base.restservice.model.DtoCrudModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.util.List;
import java.util.Map;
import java.util.Optional;

public interface BaseDbService <T extends TOpenSimpleDbEntity>{
	T save(T entity);

	<S extends T> Iterable<S> saveAll(Iterable<S> entities);

	T update(T entity);

	<S extends T> Iterable<S> updateAll(Iterable<S> entities);

	Optional<T> findById(String id);

	T findAndCheckById(String id);

	T findObjectById(String id);

	boolean existsById(String id);


	T validateById(String id);

	Iterable<T> findAll();

	Iterable<T> findAllById(Iterable<String> ids);

	long count();

	long nextValFromSequence(SequenceType seqType);

	/**
	 *
	 * @param seqType : sequence type
	 * @param  count : how many sequence value will be returned
	 * @return : list of sequence values
	 */
	List<Long> nextMultipleValFromSequence(SequenceType seqType, int count);

	void deleteById(String id);

	void delete(T entity);

	void deleteAllById(Iterable<String> ids);

	void deleteAll(Iterable<? extends T> entities);

	void deleteAll();

	Iterable<T> findAll(Sort sort);

	Page<T> findAll(Pageable pageable);

	void flush();

	void detach(T t);

	public <D extends DtoBaseModel> D toDTO(T t);

	public <D extends DtoBaseModel> List<D> toDTOList(List<T> tList);

	public <D extends DtoCrudModel> T toDAOForInsert(D dtoEntity);

	public <D extends DtoCrudModel> T toEntityForUpdate(D dtoEntity, T dbModel);

	T evictAndClone(T t);

	boolean isCanCopy(T t);

	boolean isObjectExits(T t);

	CoxNameValuePair toNameValuePair(T t);

	List<CoxNameValuePair> toNameValuePair(List<T> t);

	List<Object[]> executeCustomQuery(String query, Map<String,Object> sqlParameterMap);
}
