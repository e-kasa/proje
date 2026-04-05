package com.sedcore.service;

import com.sedcore.entity.Customer;
import com.sedcore.model.AccountTransactionResponse;
import com.sedcore.model.CustomerAccountResponse;
import com.sedcore.model.CustomerPaymentDto;
import com.towpen.base.security.BaseDbService;

import java.math.BigDecimal;
import java.util.List;

public interface CustomerService extends BaseDbService<Customer> {

    /** Entity olarak müşteriyi getir — diğer servislerde entity build işlemleri için */
    Customer getEntity(String id);

    // Cari hesap işlemleri
    CustomerAccountResponse getCustomerAccount(String customerId);

    List<AccountTransactionResponse> getCustomerTransactions(String customerId);

    CustomerAccountResponse recordPayment(String customerId, CustomerPaymentDto dto);

    CustomerAccountResponse updateCreditLimit(String customerId, BigDecimal newLimit);
}
