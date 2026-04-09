package com.sedcore.controller.impl;

import com.sedcore.entity.Customer;
import com.sedcore.model.AccountTransactionResponse;
import com.sedcore.model.CustomerAccountResponse;
import com.sedcore.model.CustomerDto;
import com.sedcore.model.CustomerPaymentDto;
import com.sedcore.repository.CustomerRepository;
import com.towpen.base.exceptions.ApiResponse;
import com.sedcore.service.CustomerService;
import com.sedcore.util.EntityAuditHelper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.sedcore.util.ExceptionMapper;
import jakarta.validation.Valid;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("api/v1/customers")
@RequiredArgsConstructor
@Slf4j
public class CustomerControllerImpl {

    private final CustomerRepository customerRepository;
    private final CustomerService customerService;
    private final EntityAuditHelper entityAuditHelper;

    // GET /product/api/v1/customers
    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> list(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive
    ) {
        try {
           List<Customer> all = (List<Customer>) customerRepository.findAll();
            var filtered = all.stream()
                .filter(c -> isActive == null || isActive.equals(c.getIsActive()))
                .filter(c -> search == null
                    || (c.getName() != null && c.getName().toLowerCase().contains(search.toLowerCase()))
                    || (c.getPhone() != null && c.getPhone().contains(search))
                    || (c.getEmail() != null && c.getEmail().toLowerCase().contains(search.toLowerCase())))
                .map(this::toMap)
                .collect(Collectors.toList());
            return ResponseEntity.ok(ApiResponse.success(filtered));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Müşteri listesi hatası: {}", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_LIST_ERROR_1400));
        }
    }

    // GET /product/api/v1/customers/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getById(@PathVariable String id) {
        try {
            var customer = customerRepository.findById(id)
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
            customer = customerRepository.save(customer);
            log.info("Müşteri oluşturuldu: {}", customer.getName());
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Müşteri oluşturma hatası: {}", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_CREATE_ERROR_1401));
        }
    }

    // PUT /product/api/v1/customers/{id}
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> update(@PathVariable String id, @RequestBody CustomerDto dto) {
        try {
            Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Müşteri bulunamadı: " + id));
            if (dto.getName() != null) customer.setName(dto.getName());
            if (dto.getPhone() != null) customer.setPhone(dto.getPhone());
            if (dto.getEmail() != null) customer.setEmail(dto.getEmail());
            if (dto.getAddress() != null) customer.setAddress(dto.getAddress());
            if (dto.getNotes() != null) customer.setNotes(dto.getNotes());
            if (dto.getCustomerType() != null) customer.setCustomerType(dto.getCustomerType());
            if (dto.getTaxNumber() != null) customer.setTaxNumber(dto.getTaxNumber());
            if (dto.getTaxOffice() != null) customer.setTaxOffice(dto.getTaxOffice());
            if (dto.getCreditLimit() != null) customer.setCreditLimit(dto.getCreditLimit());
            if (dto.getPaymentTermDays() != null) customer.setPaymentTermDays(dto.getPaymentTermDays());
            if (dto.getRiskStatus() != null) customer.setRiskStatus(dto.getRiskStatus());
            if (dto.getIsActive() != null) customer.setIsActive(dto.getIsActive());
            entityAuditHelper.prepare(customer);
            customer = customerRepository.save(customer);
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_CREATE_ERROR_1401));
        }
    }

    // DELETE /product/api/v1/customers/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable String id) {
        try {
            Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            customer.setIsActive(false); // soft delete
            entityAuditHelper.prepare(customer);
            customerRepository.save(customer);
            return ResponseEntity.ok(ApiResponse.success(null));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_UPDATE_ERROR_1402));
        }
    }

    // PATCH /product/api/v1/customers/{id}/toggle-status
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggleStatus(@PathVariable String id) {
        try {
            Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
            customer.setIsActive(customer.getIsActive() == null || !customer.getIsActive());
            entityAuditHelper.prepare(customer);
            customer = customerRepository.save(customer);
            return ResponseEntity.ok(ApiResponse.success(toMap(customer)));
        } catch (TOpenException e) {

            throw e;

        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_DELETE_ERROR_1403));
        }
    }

    // GET /product/api/v1/customers/stats
    @GetMapping("/stats")
    public ResponseEntity<ApiResponse<Map<String, Object>>> stats() {
        try {
            List<Customer>  all =( List<Customer> ) customerRepository.findAll();
            Map<String, Object> stats = new HashMap<>();
            stats.put("totalCustomers", all.size());
            stats.put("activeCustomers", all.stream().filter(c -> Boolean.TRUE.equals(c.getIsActive())).count());
            stats.put("inactiveCustomers", all.stream().filter(c -> !Boolean.TRUE.equals(c.getIsActive())).count());
            stats.put("corporateCustomers", all.stream().filter(c -> c.getCustomerType() != null && c.getCustomerType().name().equals("CORPORATE")).count());
        } catch (Exception e) {
            log.error("Exception occurred", e);
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_UPDATE_ERROR_1402));
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
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_LIST_ERROR_1400));
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
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_GET_ERROR_1404));
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
            throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_GET_ERROR_1404));
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
                throw new TOpenException(new TOpenMessage(TMessageType.CUSTOMER_UPDATE_ERROR_1402));
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
        return m;
    }
}
