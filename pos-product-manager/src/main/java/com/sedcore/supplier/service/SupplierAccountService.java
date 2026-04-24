package com.sedcore.supplier.service;

import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.supplier.model.SupplierAccountResponse;
import com.towpen.base.security.BaseDbService;

import java.math.BigDecimal;

public interface SupplierAccountService extends BaseDbService<SupplierAccount> {

    /** Tedarikçi hesabını getir, yoksa sıfır bakiyeyle oluştur */
    SupplierAccount getOrCreate(Supplier supplier);

    /** SupplierAccountResponse olarak getir */
    SupplierAccountResponse getAccountResponse(String supplierId);

    /** Tedarikçiye ödeme yapıldı — currentBalance ↓  totalCredit ↑ */
    SupplierAccount applyCredit(Supplier supplier, BigDecimal amount);

    /** Tedarikçiden satın alma yapıldı — currentBalance ↑  totalDebt ↑ */
    SupplierAccount applyDebit(Supplier supplier, BigDecimal amount);

    /** Ödeme iptal edildi — currentBalance ↑  totalCredit ↓ */
    SupplierAccount reverseCredit(Supplier supplier, BigDecimal amount);

    /** Satın alma iptal edildi — currentBalance ↓  totalDebt ↓ */
    SupplierAccount reverseDebit(Supplier supplier, BigDecimal amount);

    /** Kredi limiti değişince hesaplanan alanları yenile */
    SupplierAccountResponse recalculate(String supplierId);

    /**
     * Drift düzeltme — ledger (AccountTransaction) gerçeğinden currentBalance,
     * totalDebt, totalCredit değerlerini yeniden hesaplayıp denormalize alanları
     * senkronize eder. İade değeri: önceki → yeni bakiye farkı (drift miktarı).
     */
    BigDecimal reconcile(String supplierId);

    /** Tüm tedarikçi hesapları için reconcile — toplam düzeltme sayısını döner. */
    int reconcileAll();
}
