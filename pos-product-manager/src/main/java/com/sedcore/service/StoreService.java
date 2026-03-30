package com.sedcore.service;

import com.sedcore.entity.Store;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface StoreService extends BaseDbService<Store> {

    List<Store> listActive();
}
