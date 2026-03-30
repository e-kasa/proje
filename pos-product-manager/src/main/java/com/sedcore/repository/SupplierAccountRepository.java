package com.sedcore.repository;

import com.sedcore.entity.Supplier;
import com.sedcore.entity.SupplierAccount;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SupplierAccountRepository extends BaseDaoRepository<SupplierAccount> {

    Optional<SupplierAccount> findBySupplier(Supplier supplier);

    Optional<SupplierAccount> findBySupplierId(String supplierId);
}
