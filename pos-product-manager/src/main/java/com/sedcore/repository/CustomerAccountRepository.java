package com.sedcore.repository;

import com.sedcore.entity.Customer;
import com.sedcore.entity.CustomerAccount;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CustomerAccountRepository extends BaseDaoRepository<CustomerAccount> {

    Optional<CustomerAccount> findByCustomer(Customer customer);

    Optional<CustomerAccount> findByCustomerId(String customerId);
}
