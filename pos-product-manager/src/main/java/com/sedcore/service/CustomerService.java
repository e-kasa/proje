package com.sedcore.service;

import com.sedcore.entity.Customer;
import com.towpen.base.security.BaseDbService;

public interface CustomerService extends BaseDbService<Customer> {

    /** Entity olarak müşteriyi getir — diğer servislerde entity build işlemleri için */
    Customer getEntity(String id);
}
