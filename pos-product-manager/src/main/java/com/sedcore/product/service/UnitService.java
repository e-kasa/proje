package com.sedcore.product.service;

import com.sedcore.product.entity.Unit;
import com.sedcore.product.model.UnitRequest;
import com.sedcore.product.model.UnitResponse;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface UnitService extends BaseDbService<Unit> {

    List<UnitResponse> getActiveUnits();

    List<UnitResponse> getAllUnits();

    UnitResponse createUnit(UnitRequest request);

    UnitResponse updateUnit(String id, UnitRequest request);

    void deleteUnit(String id);

    UnitResponse toggleStatus(String id);
}
