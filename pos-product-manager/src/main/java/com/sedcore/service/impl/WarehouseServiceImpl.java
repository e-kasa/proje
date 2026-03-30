package com.sedcore.service.impl;

import com.sedcore.entity.Warehouse;
import com.sedcore.repository.WarehouseRepository;
import com.sedcore.service.WarehouseService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@Transactional
public class WarehouseServiceImpl
        extends BaseDbServiceImp<WarehouseRepository, Warehouse>
        implements WarehouseService {

    @Override
    public Class<?> getDTOClassForService() {
        return Warehouse.class;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Warehouse> listActive() {
        return dao.findByIsActive(true);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Warehouse> listByStore(String storeCode) {
        return dao.findByStoreCode(storeCode);
    }
}
