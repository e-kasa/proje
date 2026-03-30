    package com.towpen.base.security;

    import com.towpen.base.annotations.process.EnumAnnotationFieldFilter;
    import com.towpen.base.annotations.process.TypeDetailAnnotationFieldFilter;
    import com.towpen.base.context.TOpenContext;
    import com.towpen.base.context.TOpenContextHolder;
    import com.towpen.base.db.model.TOpenDbEntity;
    import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
    import com.towpen.base.db.model.TOpenSimpleDbEntity;
    import com.towpen.base.db.repository.BaseDaoRepository;
    import com.towpen.base.db.sequence.SequenceType;
    import com.towpen.base.enums.model.TMessageType;
    import com.towpen.base.exceptions.TOpenException;
    import com.towpen.base.exceptions.TOpenIDRequiredException;
    import com.towpen.base.exceptions.TOpenRuntimeException;
    import com.towpen.base.exceptions.models.TMessageFactory;
    import com.towpen.base.generic.models.CoxNameValuePair;
    import com.towpen.base.restservice.model.DtoBaseModel;
    import com.towpen.base.restservice.model.DtoCrudModel;
    import com.towpen.base.restservice.model.TOpenMessage;
    import com.towpen.base.validator.IBeanValidator;
    import com.towpen.utils.ReflectionUtil;
    import com.towpen.utils.TObjectUtils;
    import com.towpen.utils.TStringUtil;
    import jakarta.persistence.EntityManager;
    import jakarta.persistence.PersistenceContext;
    import jakarta.persistence.Query;
    import lombok.extern.slf4j.Slf4j;
    import org.hibernate.Hibernate;
    import org.springframework.beans.BeanUtils;
    import org.springframework.beans.factory.annotation.Autowired;
    import org.springframework.data.domain.Page;
    import org.springframework.data.domain.Pageable;
    import org.springframework.data.domain.Sort;
    import org.springframework.transaction.annotation.Propagation;
    import org.springframework.transaction.annotation.Transactional;

    import java.lang.reflect.ParameterizedType;
    import java.math.BigDecimal;
    import java.util.*;

    @Transactional(propagation = Propagation.REQUIRED)
    @Slf4j
    public abstract class BaseDbServiceImp <E extends BaseDaoRepository<T>, T extends TOpenSimpleDbEntity> implements BaseDbService<T> {
        @PersistenceContext
        protected EntityManager entityManager;

        @Autowired
        protected E dao;

        //@Autowired
        //protected DTOManager dtoManager;

        @Autowired
        protected ISessionInstanceService sessionInstanceService;

        @Autowired
         EnumAnnotationFieldFilter enumFieldFilter;

        @Autowired
        protected TypeDetailAnnotationFieldFilter typeDetailFieldFilter;

        public abstract Class<?> getDTOClassForService();

        private String getProcessUser() {
            String userCode = sessionInstanceService.getUserCode();
            return TStringUtil.hasText(userCode) ? userCode : "syste";
        }

        private String getProcessUserCompanyCode() {
            String userCode = sessionInstanceService.getSelectedCompanyCode();
            return TStringUtil.hasText(userCode) ? userCode : "syste";
        }

        private String getCompanyCode() {
            TOpenContext context = TOpenContextHolder.getContext();
            if (context != null && context.getCompanyCode() != null)
                return context.getCompanyCode();

            return getProcessUserCompanyCode();

        }

        @Transactional(propagation = Propagation.REQUIRED)
        public T save(T entity) {
            if (log.isDebugEnabled()) {
                log.debug("inserting  new  : {} ", entity.getClass().getName());
            }
            prepareForInsert(entity);

            entity = this.dao.save(entity);

            return entity;
        }

        @Override
        public long nextValFromSequence(SequenceType seqType) {

            return ((BigDecimal) entityManager.createNativeQuery("select " + seqType + ".NEXTVAL from dual").getSingleResult()).longValue();
        }

        @Override
        public List<Long> nextMultipleValFromSequence(SequenceType seqType, int count) {
            List<BigDecimal> idList =  entityManager.createNativeQuery("select " + seqType + ".NEXTVAL from (select level from dual connect by level <= " + count + " )").getResultList();
            return idList.stream().mapToLong(BigDecimal::longValue).boxed().toList();
        }

        @Override
        public CoxNameValuePair toNameValuePair(T t) {
            return t.toNameValuePair();
        }

        @Override
        public List<CoxNameValuePair> toNameValuePair(List<T> tList) {
            List<CoxNameValuePair> pairList = new ArrayList<>();
            if (!TObjectUtils.isEmpty(tList)) {
                tList.forEach(t -> pairList.add(toNameValuePair(t)));
            }
            return pairList;
        }

        @Override
        public T findAndCheckById(String id) {

            Optional<T> optionalData = findById(id);
            if (optionalData.isEmpty()) {
                throw new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006, TMessageFactory.ofStatic(id)));
            }
            return optionalData.get();
        }

        @SuppressWarnings("unchecked")
        protected Class<T> getClazz() {
            ParameterizedType superClass = (ParameterizedType) getClass().getGenericSuperclass();
            return (Class<T>) superClass.getActualTypeArguments()[1];
        }



        @Override
        public <S extends T> Iterable<S> saveAll(Iterable<S> entities) {
            Iterator<S> entityIter = entities.iterator();
            while (entityIter.hasNext()) {
                prepareForInsert(entityIter.next());
            }

            entities = dao.saveAll(entities);
            return entities;
        }

        @Override
        public T findObjectById(String id) {
            if (TStringUtil.isNullOrBlank(id)) {
                return null;
            }
            Optional<T> value = findById(id);
            return value.isPresent() ? value.get() : null;
        }

        @Override
        public Optional<T> findById(String id) {
            return dao.findById(id);
        }

        @Override
        public boolean existsById(String id) {
            return dao.existsById(id);
        }

        @Override
        public Iterable<T> findAll() {
            return dao.findAll();
        }

        @Override
        public Iterable<T> findAllById(Iterable<String> ids) {
            return dao.findAllById(ids);
        }

        @Override
        public long count() {
            return dao.count();
        }

        @Override
        public void deleteById(String id) {
            if (log.isDebugEnabled()) {
                log.debug("deleting by id : {}", id);
            }
            dao.deleteById(id);

        }

        @Override
        public void delete(T entity) {
            if (log.isDebugEnabled()) {
                log.debug("deleting by id : {}", entity.getId());
            }
            dao.delete(entity);

        }

        @Override
        public void deleteAllById(Iterable<String> ids) {
            dao.deleteAllById(ids);

        }

        @Override
        public void deleteAll(Iterable<? extends T> entities) {
            dao.deleteAll(entities);

        }

        @Override
        public void deleteAll() {
            dao.deleteAll();

        }

        @Override
        public T validateById(String id) {
            if (!TStringUtil.hasText(id)) {
                throw new TOpenIDRequiredException();
            }
            Optional<T> objectOpt =  findById(id);
            if (objectOpt.isEmpty()) {
                throw new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006, TMessageFactory.ofStatic(id)));
            }
            return objectOpt.get();
        }

        @Override
        public Iterable<T> findAll(Sort sort) {
            return dao.findAll(sort);
        }

        @Override
        public Page<T> findAll(Pageable pageable) {
            return dao.findAll(pageable);
        }

        public <D extends DtoCrudModel> T toDAOForInsert(D dtoEntity) {
            T base = null;
            try {
                base = getClazz().getDeclaredConstructor().newInstance();
                BeanUtils.copyProperties(dtoEntity, base);
                return base;
            } catch (Exception e) {
                throw new TOpenRuntimeException(e);
            }
        }

        public <D extends DtoCrudModel> List<T> toDAOForInsert(List<D> dtoEntity) {
            List<T> list = new ArrayList<>();
            for (D d : dtoEntity) {
                list.add(toDAOForInsert(d));
            }
            return list;
        }

        public <D extends DtoCrudModel> T toEntityForUpdate(D dtoEntity, T dbModel) {
            T base = null;
            try {
                base = getClazz().getDeclaredConstructor().newInstance();
                BeanUtils.copyProperties(dtoEntity, base);
                base.setCreateTime(dbModel.getCreateTime());
                base.setCreateUser(dbModel.getCreateUser());
                base.setId(dbModel.getId());
                if (isSuperClassBaseDbCompanyEntity(dbModel)) {
                    TOpenSimpleCompanyEntity a = (TOpenSimpleCompanyEntity) dbModel;
                    ((TOpenSimpleCompanyEntity) base).setCompanyCode(a.getCompanyCode());

                }
                return base;
            } catch (Exception e) {
                throw new TOpenRuntimeException(e);
            }
        }

        @SuppressWarnings("unchecked")
        public <D extends DtoBaseModel> D toDTO(T t, Class<?> dtoClass) {

            D dtoBase;
            try {
                dtoBase = (D) dtoClass.getDeclaredConstructor().newInstance();
                BeanUtils.copyProperties(t, dtoBase);
                enumFieldFilter.processEnumFields(dtoBase, t);
                typeDetailFieldFilter.processEnumFields(dtoBase, t);
                return dtoBase;
            } catch (Exception e) {
                throw new TOpenRuntimeException(e);
            }
        }

        public <D extends DtoBaseModel> List<D> toDTOList(List<T> tList, Class<?> clazz) {

            List<D> dtoList = new ArrayList<>();
            if (tList != null && !tList.isEmpty()) {
                for (T t : tList) {
                    dtoList.add(toDTO(t, clazz));
                }
            }
            return dtoList;
        }

        public <D extends DtoBaseModel> D toDTO(T t) {

            return toDTO(t, getDTOClassForService());

        }

        public <D extends DtoBaseModel> List<D> toDTOList(List<T> tList) {

            List<D> dtoList = new ArrayList<>();
            if (tList != null && !tList.isEmpty()) {
                for (T t : tList) {
                    dtoList.add(toDTO(t));
                }
            }
            return dtoList;
        }

        @Override
        public void flush() {
            entityManager.flush();

        }

        @Override
        public boolean isCanCopy(T t) {
            return (isObjectExits(t)) && Hibernate.isInitialized(t);
        }

        @Override
        public boolean isObjectExits(T t) {
            return t != null && !TStringUtil.isNullOrBlank(t.getId());
        }

        @Override
        public T evictAndClone(T t) {
            detach(t);
            try {
                @SuppressWarnings("unchecked")
                T copy = (T) t.getClass().getDeclaredConstructor().newInstance();
                BeanUtils.copyProperties(t, copy);
                copy.setId(null);
                copy.setCreateTime(null);
                copy.setLastModifiedTime(null);
                copy.setCreateUser(null);
                copy.setUpdateUser(null);
                return copy;
            } catch (Exception e) {
                log.error(e.getMessage());
            }
            return null;
        }

        @Override
        public void detach(T t) {
            entityManager.detach(t);

        }

        @Override
        public List<Object[]> executeCustomQuery(String query, Map<String, Object> sqlParameterMap) {
            Query dbQuery = entityManager.createQuery(query);
            if (sqlParameterMap != null && !sqlParameterMap.isEmpty()) {
                Set<String> keys = sqlParameterMap.keySet();
                for (String key : keys) {
                    dbQuery.setParameter(key, sqlParameterMap.get(key));
                }
            }
            return dbQuery.getResultList();
        }

        @Override
        public T update(T entity) {
            prepareForUpdate(entity);
            return entityManager.merge(entity);

        }

        @Override
        public <S extends T> Iterable<S> updateAll(Iterable<S> entities) {
            entities.forEach(this::update);
            return entities;
        }

        private void prepareForUpdate(T t) {
            String loginUserId = getProcessUser();
            if (this.canAddCreateAndUpdateInformations(t)) {
                t.setUpdateUser(loginUserId);
                t.setLastModifiedTime(Calendar.getInstance().getTime());
            }
        }

        private void prepareForInsert(T t) {
            String companyCode = getCompanyCode();
            String loginUserId = getProcessUser();
            if (this.canAddCreateAndUpdateInformations(t)) {
                t.setCreateUser(loginUserId);
                t.setCreateTime(Calendar.getInstance().getTime());
            }
            if (canAddCompanyCodeInformations(t)) {
                TOpenSimpleCompanyEntity a = (TOpenSimpleCompanyEntity) t;
                a.setCompanyCode(companyCode);
            }

        }

        private boolean isSuperClassBaseDbCompanyEntity(T t) {
            return ReflectionUtil.isSuperClass(t, TOpenSimpleCompanyEntity.class);
        }

        private boolean canAddCreateAndUpdateInformations(T t) {
            return ReflectionUtil.isSuperClass(t, TOpenSimpleDbEntity.class);
        }

        private boolean canAddCompanyCodeInformations(T t) {
            return ReflectionUtil.isSuperClass(t, TOpenSimpleCompanyEntity.class);

        }
    }
