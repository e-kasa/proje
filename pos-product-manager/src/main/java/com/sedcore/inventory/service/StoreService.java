package com.sedcore.inventory.service;

import com.sedcore.inventory.entity.Store;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface StoreService extends BaseDbService<Store> {

    List<Store> listActive();

    void deleteStore(String id, String companyCode);
}
