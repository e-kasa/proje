package com.sedcore.service.impl;

import com.sedcore.entity.Store;
import com.sedcore.repository.StoreRepository;
import com.sedcore.service.StoreService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class StoreServiceImpl
        extends BaseDbServiceImp<StoreRepository, Store>
        implements StoreService {

    @Override
    public Class<?> getDTOClassForService() {
        return Store.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Store> listActive() {
        return dao.findByIsActive(true);
    }
}
