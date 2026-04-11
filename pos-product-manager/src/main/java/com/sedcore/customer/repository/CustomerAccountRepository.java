package com.sedcore.customer.repository;

import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CustomerAccountRepository extends BaseDaoRepository<CustomerAccount> {

    Optional<CustomerAccount> findByCustomer(Customer customer);

    Optional<CustomerAccount> findByCustomerId(String customerId);
}
