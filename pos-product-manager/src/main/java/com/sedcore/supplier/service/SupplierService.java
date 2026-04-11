package com.sedcore.supplier.service;

import com.sedcore.supplier.entity.Supplier;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.supplier.model.SupplierAccountResponse;
import com.sedcore.supplier.model.SupplierDto;
import com.sedcore.supplier.model.SupplierPaymentDto;
import com.sedcore.supplier.model.SupplierResponse;
import com.towpen.base.security.BaseDbService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.util.List;

public interface SupplierService extends BaseDbService<Supplier> {

    Supplier createSupplier(SupplierDto dto);

    SupplierResponse getSupplier(String id);

    Page<SupplierResponse> listSuppliers(Pageable pageable, Boolean isActive);

    SupplierResponse updateSupplier(String id, SupplierDto dto);

    void deleteSupplier(String id);

    SupplierResponse toggleStatus(String id);

    // Cari hesap işlemleri
    SupplierAccountResponse getSupplierAccount(String supplierId);

    List<AccountTransactionResponse> getSupplierTransactions(String supplierId);

    SupplierAccountResponse recordPayment(String supplierId, SupplierPaymentDto dto);

    SupplierAccountResponse updateCreditLimit(String supplierId, BigDecimal newLimit);
}
