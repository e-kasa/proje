package com.sedcore.customer.repository;

import com.sedcore.customer.entity.Customer;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends BaseDaoRepository<Customer> {

    Optional<Customer> findByBankName(String bankName);

    List<Customer> findAllByOrderByIdAsc();
}
