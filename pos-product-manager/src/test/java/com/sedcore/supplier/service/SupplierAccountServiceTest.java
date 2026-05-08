package com.sedcore.supplier.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.entity.SupplierAccount;
import com.sedcore.supplier.repository.SupplierAccountRepository;
import com.sedcore.supplier.repository.SupplierRepository;
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
 * Sprint 33 — Issue P2.7 paralel coverage: Supplier ↔ Customer pattern.
 *
 * <p>Sprint 31'in {@code CustomerAccountServiceTest}'i ile birebir paralel.
 * Tedarikçi domain'inde aynı ledger math + getOrCreate idempotency +
 * recalculate boundary'lerinin çalıştığını doğrular.
 *
 * <p>Tedarikçi cari "biz borçluyuz" perspektifinde:
 * <ul>
 *   <li>{@code applyDebit} = bizim tedarikçiye borcumuz arttı (mal aldık)</li>
 *   <li>{@code applyCredit} = ödediğimiz para = borç azaldı</li>
 *   <li>currentBalance pozitif = tedarikçiye borcumuz var</li>
 * </ul>
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class SupplierAccountServiceTest {

    private static final String TENANT = "SUPACC";

    @Autowired private SupplierAccountService supplierAccountService;
    @Autowired private SupplierRepository supplierRepository;
    @Autowired private SupplierAccountRepository accountRepository;
    @Autowired private EntityManager em;

    @BeforeEach
    void setUp() {
        CompanyContext.set(TENANT);
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
    @DisplayName("applyDebit — bizim borç arttı (mal alındı)")
    void applyDebit_increasesBalanceAndDebt() {
        Supplier s = createSupplier("Sup-Debit");
        em.flush();

        SupplierAccount acct = supplierAccountService.applyDebit(s, new BigDecimal("750.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("750.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("750.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("0");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(1L);
    }

    @Test
    @Transactional
    @DisplayName("applyCredit — bize ödeme/iade — borç azalır")
    void applyCredit_decreasesBalanceIncreasesCredit() {
        Supplier s = createSupplier("Sup-Credit");
        em.flush();
        supplierAccountService.applyDebit(s, new BigDecimal("1000.00"));

        SupplierAccount acct = supplierAccountService.applyCredit(s, new BigDecimal("400.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("600.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("1000.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("400.00");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(2L);
    }

    @Test
    @Transactional
    @DisplayName("reverseCredit — applyCredit'i iptal eder")
    void reverseCredit_reversesAppliedCredit() {
        Supplier s = createSupplier("Sup-Reverse");
        em.flush();
        supplierAccountService.applyDebit(s, new BigDecimal("200.00"));
        supplierAccountService.applyCredit(s, new BigDecimal("80.00"));

        SupplierAccount acct = supplierAccountService.reverseCredit(s, new BigDecimal("80.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("200.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("0");
    }

    @Test
    @Transactional
    @DisplayName("Birden fazla applyDebit kümülatif")
    void applyDebit_cumulative() {
        Supplier s = createSupplier("Sup-Multi");
        em.flush();

        supplierAccountService.applyDebit(s, new BigDecimal("100.00"));
        supplierAccountService.applyDebit(s, new BigDecimal("250.00"));
        SupplierAccount acct = supplierAccountService.applyDebit(s, new BigDecimal("50.00"));

        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("400.00");
        assertThat(acct.getTotalDebt()).isEqualByComparingTo("400.00");
        assertThat(acct.getTotalTransactionCount()).isEqualTo(3L);
    }

    @Test
    @Transactional
    @DisplayName("applyCredit applyDebit'i aşarsa negatif bakiye (avans verdik)")
    void applyCredit_exceedingDebit_createsNegativeBalance() {
        Supplier s = createSupplier("Sup-Prepaid");
        em.flush();
        supplierAccountService.applyDebit(s, new BigDecimal("100.00"));

        SupplierAccount acct = supplierAccountService.applyCredit(s, new BigDecimal("300.00"));

        // -200 = tedarikçiye 200 avans verdik
        assertThat(acct.getCurrentBalance()).isEqualByComparingTo("-200.00");
        assertThat(acct.getTotalCredit()).isEqualByComparingTo("300.00");
    }

    @Test
    @Transactional
    @DisplayName("getOrCreate idempotent — aynı tedarikçi için yeni satır yaratmaz")
    void getOrCreate_reusesExistingAccount() {
        Supplier s = createSupplier("Sup-Idem");
        em.flush();

        SupplierAccount first = supplierAccountService.applyDebit(s, new BigDecimal("100.00"));
        SupplierAccount second = supplierAccountService.applyCredit(s, new BigDecimal("50.00"));

        assertThat(second.getId()).isEqualTo(first.getId());
        // SupplierAccount @Version yok (Customer'la mimari fark — bkz. ledger-concurrency-defense-in-depth)
        assertThat(accountRepository.findBySupplierId(s.getId())).isPresent();
        // Tek satır kaldı (yeni insert olmadı)
        assertThat(second.getCurrentBalance()).isEqualByComparingTo("50.00");
    }

    @Test
    @Transactional
    @DisplayName("recalculate availableCreditLimit ve isCreditLimitExceeded'i tazeler")
    void recalculate_refreshesCalculatedFields() {
        Supplier s = createSupplier("Sup-Limited");
        s.setCreditLimit(new BigDecimal("500.00"));
        supplierRepository.save(s);
        em.flush();
        supplierAccountService.applyDebit(s, new BigDecimal("700.00"));

        var resp = supplierAccountService.recalculate(s.getId());

        // Limit 500, borcumuz 700 → -200 limit aşıldı (biz aşırı borçluyuz)
        assertThat(resp.getAvailableCreditLimit()).isEqualByComparingTo("-200.00");
        assertThat(resp.getIsCreditLimitExceeded()).isTrue();
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private Supplier createSupplier(String name) {
        Supplier s = Supplier.builder()
                .name(name)
                .creditLimit(BigDecimal.ZERO)
                .paymentTermDays(30)
                .isActive(true)
                .isDeleted(false)
                .build();
        s.setCompanyCode(TENANT);
        s.setCreateUser("SYSTEM");
        s.setCreateTime(Calendar.getInstance().getTime());
        return supplierRepository.save(s);
    }
}
