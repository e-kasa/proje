package com.sedcore.finance.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.enums.PaymentType;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.repository.CustomerRepository;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.finance.entity.Payment;
import com.sedcore.finance.repository.PaymentRepository;
import com.sedcore.supplier.entity.Supplier;
import com.sedcore.supplier.repository.SupplierRepository;
import com.sedcore.supplier.service.SupplierAccountService;
import com.towpen.base.context.TOpenContext;
import com.towpen.base.context.TOpenContextHolder;
import com.towpen.base.exceptions.TOpenException;
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
import java.time.LocalDateTime;
import java.util.Calendar;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Sprint 31 — Issue P2.7 T1-light + T4: PaymentService entegrasyon testi.
 *
 * <p>Kapsam (mevcut production servis API'si üzerinden):
 * <ul>
 *   <li>{@code savePayment} — temel persist</li>
 *   <li>{@code cancelPayment} müşteri ödemesi → bakiye reverse</li>
 *   <li>{@code cancelPayment} tedarikçi ödemesi → bakiye reverse</li>
 *   <li>{@code cancelPayment} iptal edilmişe ikinci kez → exception (idempotency check)</li>
 *   <li>{@code verifyPayment} — onay işlemi</li>
 *   <li>{@code verifyPayment} iptal edilmişe → exception</li>
 * </ul>
 *
 * <p>{@link com.sedcore.finance.service.PaymentService#cancelPayment} ledger ↔
 * denormalize bütünlüğünün test ettiği kritik path. T4 plan'da bu yer altıydı.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class PaymentServiceTest {

    private static final String TENANT = "PMTSVC";

    @Autowired private PaymentService paymentService;
    @Autowired private PaymentRepository paymentRepository;
    @Autowired private CustomerRepository customerRepository;
    @Autowired private SupplierRepository supplierRepository;
    @Autowired private CustomerAccountService customerAccountService;
    @Autowired private SupplierAccountService supplierAccountService;
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
    @DisplayName("savePayment temel persist — ID + companyCode + createTime dolar")
    void savePayment_persistsWithDefaults() {
        Customer c = createCustomer("Pay-1");
        em.flush();

        Payment p = Payment.builder()
                .customer(c)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("150.00"))
                .paymentDate(LocalDateTime.now())
                .description("Test")
                .isCancelled(false)
                .isVerified(false)
                .build();
        Payment saved = paymentService.savePayment(p);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCompanyCode()).isEqualTo(TENANT);
        assertThat(saved.getCreateTime()).isNotNull();
    }

    @Test
    @Transactional
    @DisplayName("cancelPayment müşteri ödemesi → CustomerAccount.reverseCredit çağrılır")
    void cancelPayment_customer_reversesAccountBalance() {
        Customer c = createCustomer("Pay-Cust");
        em.flush();
        // 500 borç, 200 ödeme alındı
        customerAccountService.applyDebit(c, new BigDecimal("500.00"));
        customerAccountService.applyCredit(c, new BigDecimal("200.00"));

        Payment payment = paymentService.savePayment(Payment.builder()
                .customer(c)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("200.00"))
                .paymentDate(LocalDateTime.now())
                .isCancelled(false)
                .isVerified(false)
                .build());

        // Bakiye: 500 - 200 = 300
        assertThat(customerAccountService.getAccountResponse(c.getId())
                .getCurrentBalance()).isEqualByComparingTo("300.00");

        // Ödeme iptali
        var resp = paymentService.cancelPayment(payment.getId(), "test iptal");

        assertThat(resp.getIsCancelled()).isTrue();
        // Bakiye geri 500'e döner (ödeme silindi)
        assertThat(customerAccountService.getAccountResponse(c.getId())
                .getCurrentBalance()).isEqualByComparingTo("500.00");
    }

    @Test
    @Transactional
    @DisplayName("cancelPayment tedarikçi ödemesi → SupplierAccount.reverseCredit çağrılır")
    void cancelPayment_supplier_reversesAccountBalance() {
        Supplier s = createSupplier("Pay-Sup");
        em.flush();
        // Tedarikçiye 400 borç, 150 ödedik
        supplierAccountService.applyDebit(s, new BigDecimal("400.00"));
        supplierAccountService.applyCredit(s, new BigDecimal("150.00"));

        Payment payment = paymentService.savePayment(Payment.builder()
                .supplier(s)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("150.00"))
                .paymentDate(LocalDateTime.now())
                .isCancelled(false)
                .isVerified(false)
                .build());

        // Bakiye: 400 - 150 = 250
        assertThat(supplierAccountService.getAccountResponse(s.getId())
                .getCurrentBalance()).isEqualByComparingTo("250.00");

        var resp = paymentService.cancelPayment(payment.getId(), "supplier iptal");

        assertThat(resp.getIsCancelled()).isTrue();
        // Bakiye geri 400'e döner
        assertThat(supplierAccountService.getAccountResponse(s.getId())
                .getCurrentBalance()).isEqualByComparingTo("400.00");
    }

    @Test
    @Transactional
    @DisplayName("cancelPayment ikinci kez çağrılırsa exception — idempotency guard")
    void cancelPayment_alreadyCancelled_throws() {
        Customer c = createCustomer("Pay-Idem");
        em.flush();
        customerAccountService.applyDebit(c, new BigDecimal("100.00"));

        Payment payment = paymentService.savePayment(Payment.builder()
                .customer(c)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("100.00"))
                .paymentDate(LocalDateTime.now())
                .isCancelled(false)
                .isVerified(false)
                .build());

        paymentService.cancelPayment(payment.getId(), "ilk iptal");

        assertThatThrownBy(() ->
                paymentService.cancelPayment(payment.getId(), "ikinci iptal"))
                .isInstanceOf(TOpenException.class);
    }

    @Test
    @Transactional
    @DisplayName("verifyPayment isVerified=true yapar")
    void verifyPayment_marksVerified() {
        Customer c = createCustomer("Pay-Verify");
        em.flush();

        Payment payment = paymentService.savePayment(Payment.builder()
                .customer(c)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("75.00"))
                .paymentDate(LocalDateTime.now())
                .isCancelled(false)
                .isVerified(false)
                .build());

        var resp = paymentService.verifyPayment(payment.getId(), "test-admin");

        assertThat(resp.getIsVerified()).isTrue();
    }

    @Test
    @Transactional
    @DisplayName("verifyPayment iptal edilmiş ödemeye → exception")
    void verifyPayment_onCancelled_throws() {
        Customer c = createCustomer("Pay-VerifyCancel");
        em.flush();
        customerAccountService.applyDebit(c, new BigDecimal("100.00"));

        Payment payment = paymentService.savePayment(Payment.builder()
                .customer(c)
                .paymentType(PaymentType.CASH)
                .amount(new BigDecimal("100.00"))
                .paymentDate(LocalDateTime.now())
                .isCancelled(false)
                .isVerified(false)
                .build());
        paymentService.cancelPayment(payment.getId(), "cancel");

        assertThatThrownBy(() ->
                paymentService.verifyPayment(payment.getId(), "admin"))
                .isInstanceOf(TOpenException.class);
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
