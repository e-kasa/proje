package com.sedcore.sales.service.impl;

import com.sedcore.sales.entity.Sale;
import com.sedcore.sales.repository.SaleRepository;
import com.sedcore.sales.service.SaleService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
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
