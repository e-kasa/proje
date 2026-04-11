package com.sedcore.inventory.service;

import com.sedcore.inventory.entity.Warehouse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface WarehouseService extends BaseDbService<Warehouse> {

    List<Warehouse> listActive();

    List<Warehouse> listByStore(String storeCode);
}
