package com.sedcore.service.impl;

import com.sedcore.entity.Customer;
import com.sedcore.repository.CustomerRepository;
import com.sedcore.service.CustomerService;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
@Transactional
public class CustomerServiceImpl
        extends BaseDbServiceImp<CustomerRepository, Customer>
        implements CustomerService {

    @Override
    public Class<?> getDTOClassForService() {
        return Customer.class;
    }

    @Override
    @Transactional(readOnly = true)
    public Customer getEntity(String id) {
        return findById(id)
                .orElseThrow(() -> new RuntimeException("Musteri bulunamadi: " + id));
    }
}
