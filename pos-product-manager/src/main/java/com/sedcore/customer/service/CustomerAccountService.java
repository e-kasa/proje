package com.sedcore.customer.service;

import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.model.CustomerAccountResponse;
import com.towpen.base.security.BaseDbService;

import java.math.BigDecimal;

public interface CustomerAccountService extends BaseDbService<CustomerAccount> {

    /** Müşteri hesabını getir, yoksa sıfır bakiyeyle oluştur */
    CustomerAccount getOrCreate(Customer customer);

    /** Müşteri cari hesap bilgilerini DTO olarak getir */
    CustomerAccountResponse getAccountResponse(String customerId);

    /**
     * Müşteriden tahsilat yapıldı — bakiye azalır (müşteri borcunu ödedi)
     * currentBalance ↓  totalCredit ↑
     */
    CustomerAccount applyCredit(Customer customer, BigDecimal amount);

    /**
     * Müşteriye satış yapıldı — bakiye artar (müşteri borçlandı)
     * currentBalance ↑  totalDebt ↑
     */
    CustomerAccount applyDebit(Customer customer, BigDecimal amount);

    /**
     * Tahsilat iptal edildi — bakiyeyi geri yükle
     * currentBalance ↑  totalCredit ↓
     */
    CustomerAccount reverseCredit(Customer customer, BigDecimal amount);

    /** Kredi limiti değişince hesaplanan alanları güncelle */
    CustomerAccountResponse recalculate(String customerId);

    /**
     * Drift düzeltme — ledger (AccountTransaction) gerçeğinden currentBalance,
     * totalDebt, totalCredit değerlerini yeniden hesaplayıp denormalize alanları
     * senkronize eder. İade değeri: önceki → yeni bakiye farkı (drift miktarı).
     */
    BigDecimal reconcile(String customerId);

    /** Tüm müşteri hesapları için reconcile — toplam düzeltme sayısını döner. */
    int reconcileAll();
}
