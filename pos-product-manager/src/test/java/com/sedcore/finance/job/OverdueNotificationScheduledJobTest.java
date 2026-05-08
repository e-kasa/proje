package com.sedcore.finance.job;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.customer.entity.Customer;
import com.sedcore.customer.entity.CustomerAccount;
import com.sedcore.notification.dto.NotificationDto;
import com.sedcore.notification.dto.NotificationRequestDto;
import com.sedcore.notification.entity.NotificationChannel;
import com.sedcore.notification.entity.NotificationStatus;
import com.sedcore.notification.service.NotificationService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;

import java.math.BigDecimal;
import java.util.Calendar;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Sprint 30 — issue P2.4 scheduled job testi.
 *
 * <p>Kapsam:
 * <ul>
 *   <li>Email dolu müşteri → EMAIL kanalı queue
 *   <li>Yalnız phone dolu müşteri → SMS kanalı queue
 *   <li>İki kanal da yok → skip (repository sorgusu zaten filtreli)
 *   <li>{@code overdueAmount = 0} → repository döndürmez, queue çağrılmaz
 *   <li>NotificationService hata fırlatırsa skip sayılır, batch durmaz
 * </ul>
 *
 * <p>{@link NotificationService} mock'lanır — gerçek SMTP / Twilio çağrılmaz,
 * yalnız {@code queue()} parametresi inceleniyor.
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
        "overdue.notification.enabled=true"
})
class OverdueNotificationScheduledJobTest {

    private static final String TENANT = "OVD_T";

    @Autowired private OverdueNotificationScheduledJob job;
    @Autowired private EntityManager em;

    @MockBean private NotificationService notificationService;

    @BeforeEach
    void setUp() {
        CompanyContext.set(TENANT);
        when(notificationService.queue(any(NotificationRequestDto.class)))
                .thenReturn(NotificationDto.builder()
                        .id("mock-notif-id")
                        .status(NotificationStatus.PENDING)
                        .build());
    }

    @AfterEach
    void tearDown() {
        CompanyContext.clear();
    }

    @Test
    @Transactional
    @DisplayName("Email dolu overdue müşteri → EMAIL queue çağrılır")
    void scanTenant_overdueWithEmail_queuesEmail() {
        createOverdueCustomer("ali@test.com", null, new BigDecimal("250.00"));
        em.flush();

        OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

        assertThat(r.queued()).isEqualTo(1);
        assertThat(r.skipped()).isZero();
        verify(notificationService, times(1)).queue(argThatChannelIs(NotificationChannel.EMAIL));
    }

    @Test
    @Transactional
    @DisplayName("Yalnız phone dolu overdue müşteri → SMS fallback")
    void scanTenant_overdueWithPhoneOnly_queuesSms() {
        createOverdueCustomer(null, "5551112233", new BigDecimal("100.00"));
        em.flush();

        OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

        assertThat(r.queued()).isEqualTo(1);
        verify(notificationService, times(1)).queue(argThatChannelIs(NotificationChannel.SMS));
    }

    @Test
    @Transactional
    @DisplayName("Email > Phone preference — ikisi de varsa EMAIL seçilir")
    void scanTenant_bothChannels_prefersEmail() {
        createOverdueCustomer("dual@test.com", "5559998877", new BigDecimal("500.00"));
        em.flush();

        job.scanTenant();

        verify(notificationService, times(1)).queue(argThatChannelIs(NotificationChannel.EMAIL));
        verify(notificationService, never()).queue(argThatChannelIs(NotificationChannel.SMS));
    }

    @Test
    @Transactional
    @DisplayName("overdueAmount=0 müşteri queue çağırmaz")
    void scanTenant_zeroOverdue_skipped() {
        createCustomerWithAccount("zero@test.com", null,
                new BigDecimal("100.00"), BigDecimal.ZERO);
        em.flush();

        OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

        assertThat(r.queued()).isZero();
        assertThat(r.skipped()).isZero();
        verify(notificationService, never()).queue(any(NotificationRequestDto.class));
    }

    @Test
    @Transactional
    @DisplayName("İletişim kanalı yok → repository filtreler, kayıt görünmez")
    void scanTenant_noContact_filteredByQuery() {
        createCustomerWithAccount(null, null,
                new BigDecimal("500.00"), new BigDecimal("100.00"));
        em.flush();

        OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

        assertThat(r.queued()).isZero();
        verify(notificationService, never()).queue(any(NotificationRequestDto.class));
    }

    @Test
    @Transactional
    @DisplayName("Queue exception fırlatırsa batch durmaz, skipped artar")
    void scanTenant_queueThrows_continuesBatch() {
        createOverdueCustomer("err@test.com", null, new BigDecimal("100.00"));
        createOverdueCustomer("ok@test.com", null, new BigDecimal("200.00"));
        em.flush();

        // İlk çağrı patlasın, ikinci başarılı olsun
        when(notificationService.queue(any(NotificationRequestDto.class)))
                .thenThrow(new RuntimeException("smtp down"))
                .thenReturn(NotificationDto.builder()
                        .id("ok").status(NotificationStatus.PENDING).build());

        OverdueNotificationScheduledJob.ScanResult r = job.scanTenant();

        assertThat(r.queued() + r.skipped()).isEqualTo(2);
        assertThat(r.skipped()).isGreaterThanOrEqualTo(1);
        verify(notificationService, atLeastOnce()).queue(any(NotificationRequestDto.class));
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private NotificationRequestDto argThatChannelIs(NotificationChannel ch) {
        return org.mockito.ArgumentMatchers.argThat(req -> req != null && req.getChannel() == ch);
    }

    private Customer createOverdueCustomer(String email, String phone, BigDecimal overdue) {
        return createCustomerWithAccount(email, phone, overdue, overdue);
    }

    private Customer createCustomerWithAccount(String email, String phone,
                                                BigDecimal balance, BigDecimal overdue) {
        Customer c = Customer.builder()
                .name("Test " + (email != null ? email : phone != null ? phone : "no-contact"))
                .email(email)
                .phone(phone)
                .creditLimit(BigDecimal.ZERO)
                .paymentTermDays(30)
                .isActive(true)
                .isDeleted(false)
                .build();
        c.setCompanyCode(TENANT);
        c.setCreateUser("SYSTEM");
        c.setCreateTime(Calendar.getInstance().getTime());
        em.persist(c);

        CustomerAccount a = CustomerAccount.builder()
                .customer(c)
                .currentBalance(balance)
                .totalDebt(balance)
                .totalCredit(BigDecimal.ZERO)
                .overdueAmount(overdue)
                .availableCreditLimit(BigDecimal.ZERO)
                .isCreditLimitExceeded(false)
                .totalTransactionCount(0L)
                .build();
        a.setCompanyCode(TENANT);
        a.setCreateUser("SYSTEM");
        a.setCreateTime(Calendar.getInstance().getTime());
        em.persist(a);

        return c;
    }
}
