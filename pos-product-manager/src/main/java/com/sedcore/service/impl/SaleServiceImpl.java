package com.sedcore.service.impl;

import com.sedcore.entity.Sale;
import com.sedcore.repository.SaleRepository;
import com.sedcore.service.SaleService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Slf4j
@Transactional
public class SaleServiceImpl
        extends BaseDbServiceImp<SaleRepository, Sale>
        implements SaleService {

    @Override
    public Class<?> getDTOClassForService() {
        return Sale.class;
    }

    @Override
    @Transactional(readOnly = true)
    public Sale getEntity(String id) {
        return findById(id)
                .orElseThrow(() -> new RuntimeException("Satis bulunamadi: " + id));
    }

    @Override
    public List<Sale> findByCustomerId(String customerId) {
        return dao.findByCustomerId(customerId);
    }

    @Override
    public Optional<Sale> findBySaleNumber(String saleNumber) {
        return dao.findBySaleNumber(saleNumber);
    }
}
