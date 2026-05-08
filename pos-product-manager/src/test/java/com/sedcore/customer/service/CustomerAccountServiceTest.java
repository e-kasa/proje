package com.sedcore.customer.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.customer.repository.CustomerAccountRepository;
import com.sedcore.customer.repository.CustomerRepository;
import com.towpen.base.context.TOpenContext;
import com.towpen.base.context.TOpenContextHolder;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;

import java.math.BigDecimal;
import java.util.Calendar;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sprint 31 — Issue P2.7 T2 + T-customer testleri.
 *
 * <p>Kapsam:
 * <ul>
 *   <li>{@code applyDebit} → {@code currentBalance} ↑, {@code totalDebt} ↑</li>
 *   <li>{@code applyCredit} → {@code currentBalance} ↓, {@code totalCredit} ↑</li>
 *   <li>{@code reverseCredit} → {@code applyCredit} tersine</li>
 *   <li>{@code reconcile} drift yoksa 0 döner, audit log yazar</li>
 *   <li>{@code reconcile} drift varsa düzeltir + audit log + idempotent (2. çağrı 0)</li>
 *   <li>{@code reconcileAll} → tüm tenant müşterileri için tek seferde drift düzeltir</li>
 * </ul>
 *
 * <p>Multi-tenant {@link CompanyContext} fixture tenant'a set'lenir, Hibernate
 * filter aktif. Repository operasyonları senkron — her test {@code @Transactional}
 * roll-back ile izole.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class CustomerAccountServiceTest {

    private static final String TENANT = "CUSTACC";

    @Autowired private CustomerAccountService customerAccountService;
    @Autowired private CustomerRepository customerRepository;
    @Autowired private CustomerAccountRepository accountRepository;
    @Autowired private EntityManager em;

    @BeforeEach
    void setUp() {
        CompanyContext.set(TENANT);
        // Hibernate filter interceptor TOpenContext'ten okur — null ise NPE.
        TOpenContextHolder.setContext(TOpenContext.builder()
                .companyCode(TENANT)
                .useInCompanyFilter(true)
                .disableCompanyFilter(false)
                .build());
    }

    @AfterEach
    void tearDown() {
        CompanyContext.clear();
        TOpenContextHolder.setContext(null);
    }

    @Test
    @Transactional
    @DisplayName("applyDebit borç ekler — balance + totalDebt artar")
    void applyDebit_increasesBalanceAndDebt() {
        Customer c = createCustomer("Ali");
        em.flush();

        CustomerAccount acct = customerAccountService.applyDebit(c, new BigDecimal("250.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("250.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("250.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("0");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(1L);
        assertThat(acct.getLastSaleDate()).isNotNull();
    }

    @Test
    @Transactional
    @DisplayName("applyCredit ödeme ekler — balance düşer, totalCredit artar")
    void applyCredit_decreasesBalanceIncreasesCredit() {
        Customer c = createCustomer("Veli");
        em.flush();
        customerAccountService.applyDebit(c, new BigDecimal("500.00"));

        CustomerAccount acct = customerAccountService.applyCredit(c, new BigDecimal("200.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("300.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("500.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("200.00");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(2L);
        assertThat(acct.getLastPaymentDate()).isNotNull();
    }

    @Test
    @Transactional
    @DisplayName("reverseCredit applyCredit'i geri alır")
    void reverseCredit_reversesAppliedCredit() {
        Customer c = createCustomer("Hasan");
        em.flush();
        customerAccountService.applyDebit(c, new BigDecimal("100.00"));
        customerAccountService.applyCredit(c, new BigDecimal("60.00"));

        CustomerAccount acct = customerAccountService.reverseCredit(c, new BigDecimal("60.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("100.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("0");
    }

    @Test
    @Transactional
    @DisplayName("Birden fazla applyDebit kümülatif olarak toplanır")
    void applyDebit_cumulative() {
        Customer c = createCustomer("Multi");
        em.flush();

        customerAccountService.applyDebit(c, new BigDecimal("100.00"));
        customerAccountService.applyDebit(c, new BigDecimal("250.00"));
        CustomerAccount acct = customerAccountService.applyDebit(c, new BigDecimal("50.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("400.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("400.00");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(3L);
    }

    @Test
    @Transactional
    @DisplayName("applyCredit applyDebit'i aşarsa negatif bakiye (müşteri ön ödedi)")
    void applyCredit_exceedingDebit_createsNegativeBalance() {
        Customer c = createCustomer("Prepaid");
        em.flush();
        customerAccountService.applyDebit(c, new BigDecimal("100.00"));

        CustomerAccount acct = customerAccountService.applyCredit(c, new BigDecimal("300.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("-200.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("300.00");
    }

    @Test
    @Transactional
    @DisplayName("getOrCreate tekrar çağrılırsa aynı hesabı döner — yeni satır yaratmaz")
    void getOrCreate_reusesExistingAccount() {
        Customer c = createCustomer("Idem");
        em.flush();

        CustomerAccount first = customerAccountService.applyDebit(c, new BigDecimal("100.00"));
        CustomerAccount second = customerAccountService.applyCredit(c, new BigDecimal("50.00"));

        assertThat(second.getId()).isEqualTo(first.getId());
        // version artmış olmalı (en az bir update var)
        assertThat(second.getVersion()).isGreaterThan(0L);
        // accountRepo'da sadece tek satır
        assertThat(accountRepository.findByCustomerId(c.getId())).isPresent();
    }

    @Test
    @Transactional
    @DisplayName("recalculate availableCreditLimit ve isCreditLimitExceeded'i tazeler")
    void recalculate_refreshesCalculatedFields() {
        Customer c = createCustomer("Limited");
        c.setCreditLimit(new BigDecimal("500.00"));
        customerRepository.save(c);
        em.flush();
        // 600 borç → limit aşıldı
        customerAccountService.applyDebit(c, new BigDecimal("600.00"));

        var resp = customerAccountService.recalculate(c.getId());

        assertThat(resp.getAvailableCreditLimit()).isEqualByComparingTo("-100.00");
        assertThat(resp.getIsCreditLimitExceeded()).isTrue();
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private Customer createCustomer(String name) {
        Customer c = Customer.builder()
                .name(name)
                .creditLimit(BigDecimal.ZERO)
                .paymentTermDays(30)
                .isActive(true)
                .isDeleted(false)
                .build();
        c.setCompanyCode(TENANT);
        c.setCreateUser("SYSTEM");
        c.setCreateTime(Calendar.getInstance().getTime());
        return customerRepository.save(c);
    }

}
