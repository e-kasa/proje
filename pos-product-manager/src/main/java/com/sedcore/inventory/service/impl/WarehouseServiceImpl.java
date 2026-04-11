package com.sedcore.inventory.service.impl;

import com.sedcore.inventory.entity.Warehouse;
import com.sedcore.inventory.repository.WarehouseRepository;
import com.sedcore.inventory.service.WarehouseService;
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
