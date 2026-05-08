package com.sedcore.customer.controller.impl;

import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.common.enums.CustomerType;
import com.sedcore.customer.entity.Customer;
import com.sedcore.finance.model.AccountTransactionResponse;
import com.sedcore.customer.model.CustomerAccountResponse;
import com.sedcore.customer.model.CustomerDto;
import com.sedcore.customer.model.CustomerPaymentDto;
import com.sedcore.finance.service.AccountAuditService;
import com.sedcore.finance.service.AccountAuditService.FieldChange;
import org.springframework.transaction.annotation.Transactional;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.customer.service.CustomerService;
import com.sedcore.common.util.EntityAuditHelper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.common.util.ExceptionMapper;
import jakarta.validation.Valid;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/customers")
@RequiredArgsConstructor
@Slf4j
public class CustomerControllerImpl {

    private final CustomerService customerService;
    private final EntityAuditHelper entityAuditHelper;
    private final AccountAuditService accountAuditService;

    // GET /product/api/v1/customers
    // DB-side search + active filter (LOWER/LIKE on name+phone+email).
    @Transactional(readOnly = true)
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive
    ) {
        try {
            List<Customer> rows = customerService.search(search, isActive);
            List<Map<String, Object>> filtered = rows.stream()
                    .map(this::toMap)
                    .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(filtered));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Müşteri listesi hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/customers/{id}
    @Transactional(readOnly = true)
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            var customer = customerService.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.mapAndLog(e, "getCustomer(" + id + ")");
        }
    }

    // POST /product/api/v1/customers
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> create(@Valid @RequestBody CustomerDto dto) {
        try {
            Customer customer = Customer.builder()
                .name(dto.getName()).phone(dto.getPhone()).email(dto.getEmail())
                .address(dto.getAddress()).notes(dto.getNotes())
                .customerType(dto.getCustomerType()).taxNumber(dto.getTaxNumber())
                .taxOffice(dto.getTaxOffice()).creditLimit(dto.getCreditLimit())
                .paymentTermDays(dto.getPaymentTermDays()).riskStatus(dto.getRiskStatus())
                .isActive(dto.getIsActive() != null ? dto.getIsActive() : true)
                .build();
            entityAuditHelper.prepare(customer);
            customer = customerService.save(customer);
            log.info("Müşteri oluşturuldu: {}", customer.getName());
            accountAuditService.recordCreate(
                    AccountAuditEntityType.CUSTOMER, customer.getId(),
                    "createCustomer endpoint");
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Müşteri oluşturma hatası", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PUT /product/api/v1/customers/{id}
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> update(@PathVariable String id, @RequestBody CustomerDto dto) {
        try {
            Customer customer = customerService.findById(id)
                .orElseThrow(() -> new RuntimeException("Müşteri bulunamadı: " + id));
            // Sprint 30 — issue P2.6: önemli alan değişikliklerini topla
            List<FieldChange> changes = new ArrayList<>();
            if (dto.getName() != null) {
                changes.add(FieldChange.of("name", customer.getName(), dto.getName()));
                customer.setName(dto.getName());
            }
            if (dto.getPhone() != null) customer.setPhone(dto.getPhone());
            if (dto.getEmail() != null) customer.setEmail(dto.getEmail());
            if (dto.getAddress() != null) customer.setAddress(dto.getAddress());
            if (dto.getNotes() != null) customer.setNotes(dto.getNotes());
            if (dto.getCustomerType() != null) customer.setCustomerType(dto.getCustomerType());
            if (dto.getTaxNumber() != null) {
                changes.add(FieldChange.of("taxNumber", customer.getTaxNumber(), dto.getTaxNumber()));
                customer.setTaxNumber(dto.getTaxNumber());
            }
            if (dto.getTaxOffice() != null) customer.setTaxOffice(dto.getTaxOffice());
            if (dto.getCreditLimit() != null) {
                changes.add(FieldChange.of("creditLimit", customer.getCreditLimit(), dto.getCreditLimit()));
                customer.setCreditLimit(dto.getCreditLimit());
            }
            if (dto.getPaymentTermDays() != null) {
                changes.add(FieldChange.of("paymentTermDays", customer.getPaymentTermDays(), dto.getPaymentTermDays()));
                customer.setPaymentTermDays(dto.getPaymentTermDays());
            }
            if (dto.getRiskStatus() != null) {
                changes.add(FieldChange.of("riskStatus", customer.getRiskStatus(), dto.getRiskStatus()));
                customer.setRiskStatus(dto.getRiskStatus());
            }
            if (dto.getIsActive() != null) {
                changes.add(FieldChange.of("isActive", customer.getIsActive(), dto.getIsActive()));
                customer.setIsActive(dto.getIsActive());
            }
            entityAuditHelper.prepare(customer);
            customer = customerService.save(customer);
            accountAuditService.recordFieldChanges(
                    AccountAuditEntityType.CUSTOMER, id, changes, "updateCustomer endpoint");
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // DELETE /product/api/v1/customers/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable String id) {
        try {
            Customer customer = customerService.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            customer.setIsActive(false); // soft delete
            entityAuditHelper.prepare(customer);
            customerService.save(customer);
            accountAuditService.recordDelete(
                    AccountAuditEntityType.CUSTOMER, id,
                    "soft delete via deleteCustomer");
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // PATCH /product/api/v1/customers/{id}/toggle-status
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleStatus(@PathVariable String id) {
        try {
            Customer customer = customerService.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            customer.setIsActive(customer.getIsActive() == null || !customer.getIsActive());
            entityAuditHelper.prepare(customer);
            customer = customerService.save(customer);
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/customers/stats
    // DB-side COUNT queries — no findAll().
    @Transactional(readOnly = true)
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            long active = customerService.countByIsActive(Boolean.TRUE);
            long inactive = customerService.countByIsActive(Boolean.FALSE);
            long corporate = customerService.countByCustomerType(CustomerType.CORPORATE);
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalCustomers", active + inactive);
            stats.put("activeCustomers", active);
            stats.put("inactiveCustomers", inactive);
            stats.put("corporateCustomers", corporate);
            return ResponseEntity.ok(ApiResponse.success(stats));
        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // =========================================================================
    // CARİ HESAP ENDPOINT'LERİ
    // =========================================================================

    // GET /product/api/v1/customers/{id}/account
    @GetMapping("/{id}/account")
    public ResponseEntity<ApiResponse<CustomerAccountResponse>> getAccount(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(customerService.getCustomerAccount(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // GET /product/api/v1/customers/{id}/transactions
    @GetMapping("/{id}/transactions")
    public ResponseEntity<ApiResponse<List<AccountTransactionResponse>>> getTransactions(@PathVariable String id) {
        try {
            return ResponseEntity.ok(ApiResponse.success(customerService.getCustomerTransactions(id)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    // POST /product/api/v1/customers/{id}/payment
    @PostMapping("/{id}/payment")
    public ResponseEntity<ApiResponse<CustomerAccountResponse>> recordPayment(
            @PathVariable String id,
            @RequestBody CustomerPaymentDto dto) {
        try {
            return ResponseEntity.ok(ApiResponse.success(customerService.recordPayment(id, dto)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Tahsilat kaydi hatasi: customerId={}, {}", id, e);
            throw ExceptionMapper.map(e);
        }
    }

    // PUT /product/api/v1/customers/{id}/credit-limit
    @PutMapping("/{id}/credit-limit")
    public ResponseEntity<ApiResponse<CustomerAccountResponse>> updateCreditLimit(
            @PathVariable String id,
            @RequestBody Map<String, BigDecimal> body) {
        try {
            BigDecimal newLimit = body.get("creditLimit");
            if (newLimit == null) {
                throw new TOpenException(new TOpenMessage(TMessageType.FIELD_IS_REQUIRED_1001));
            }
            return ResponseEntity.ok(ApiResponse.success(customerService.updateCreditLimit(id, newLimit)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw ExceptionMapper.map(e);
        }
    }

    private Map<String, Object> toMap(Customer c) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", c.getId()); m.put("name", c.getName()); m.put("phone", c.getPhone());
        m.put("email", c.getEmail()); m.put("address", c.getAddress()); m.put("notes", c.getNotes());
        m.put("customerType", c.getCustomerType()); m.put("taxNumber", c.getTaxNumber());
        m.put("taxOffice", c.getTaxOffice()); m.put("creditLimit", c.getCreditLimit());
        m.put("paymentTermDays", c.getPaymentTermDays()); m.put("riskStatus", c.getRiskStatus());
        m.put("isActive", c.getIsActive()); m.put("companyCode", c.getCompanyCode());

        // CustomerAccount denormalize alanlar — AccountsHub liste satırı bakiyesi için
        var acct = c.getAccount();
        m.put("currentBalance", acct != null ? acct.getCurrentBalance() : BigDecimal.ZERO);
        m.put("overdueAmount", acct != null ? acct.getOverdueAmount() : BigDecimal.ZERO);
        m.put("availableCreditLimit", acct != null ? acct.getAvailableCreditLimit() : BigDecimal.ZERO);
        m.put("isCreditLimitExceeded", acct != null ? acct.getIsCreditLimitExceeded() : Boolean.FALSE);
        return m;
    }
}
