package com.sedcore.supplier.repository;

import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SupplierAccountRepository extends BaseDaoRepository<SupplierAccount> {

    Optional<SupplierAccount> findBySupplier(Supplier supplier);

    Optional<SupplierAccount> findBySupplierId(String supplierId);
}
