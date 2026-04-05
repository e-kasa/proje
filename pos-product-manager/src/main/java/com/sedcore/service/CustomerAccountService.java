package com.sedcore.service;

import com.sedcore.entity.Customer;
import com.sedcore.entity.CustomerAccount;
import com.sedcore.model.CustomerAccountResponse;
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
}
