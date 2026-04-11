package com.sedcore.customer.service;

import com.sedcore.customer.entity.Customer;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.customer.model.CustomerAccountResponse;
import com.sedcore.customer.model.CustomerPaymentDto;
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
