package com.sedcore.finance.service;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.enums.AccountAuditAction;
import com.sedcore.common.enums.AccountAuditEntityType;
import com.sedcore.finance.entity.AccountAuditLog;
import com.sedcore.finance.repository.AccountAuditLogRepository;
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

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Sprint 30 — issue P2.6 (activity history) servis testi.
 *
 * <p>Kapsam:
 * <ul>
 *   <li>Tek alan değişikliği kaydı — eski/yeni eşitse no-op
 *   <li>Çoklu alan değişikliği — eşit olanlar atlanır
 *   <li>CREATE / DELETE özet kaydı
 *   <li>getHistory en yeni üstte sıralı döner
 *   <li>1024 karakteri aşan değer kısaltılır
 * </ul>
 *
 * <p>Spring context full yüklenir — repository + service entegrasyonu birlikte
 * test edilir. {@link CompanyContext} her test için fixture tenant'a set'lenir
 * (Hibernate filter aktif).
 */
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@ActiveProfiles("test")
@TestPropertySource(properties = {
        "spring.jpa.hibernate.ddl-auto=create-drop",
        "spring.jpa.database-platform=org.hibernate.dialect.H2Dialect"
})
class AccountAuditServiceTest {

    private static final String TENANT = "AUDIT_T";

    @Autowired private AccountAuditService auditService;
    @Autowired private AccountAuditLogRepository repo;

    @BeforeEach
    void setUp() {
        CompanyContext.set(TENANT);
    }

    @AfterEach
    void tearDown() {
        CompanyContext.clear();
    }

    @Test
    @Transactional
    @DisplayName("recordFieldChange yeni alan değerini saklar")
    void recordFieldChange_persists() {
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-1", "creditLimit",
                new BigDecimal("5000"), new BigDecimal("10000"), "test");

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-1");

        assertThat(history).hasSize(1);
        AccountAuditLog log = history.get(0);
        assertThat(log.getAction()).isEqualTo(AccountAuditAction.UPDATE);
        assertThat(log.getFieldName()).isEqualTo("creditLimit");
        assertThat(log.getOldValue()).isEqualTo("5000");
        assertThat(log.getNewValue()).isEqualTo("10000");
        assertThat(log.getReason()).isEqualTo("test");
    }

    @Test
    @Transactional
    @DisplayName("recordFieldChange eski/yeni eşitse kayıt yazmaz")
    void recordFieldChange_skipsIdenticalValues() {
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-2", "name",
                "Ali Veli", "Ali Veli", null);

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-2");

        assertThat(history).isEmpty();
    }

    @Test
    @Transactional
    @DisplayName("recordFieldChanges çoklu alan toplu yazar, eşitleri atlar")
    void recordFieldChanges_writesMultipleSkipsEqual() {
        List<AccountAuditService.FieldChange> changes = List.of(
                AccountAuditService.FieldChange.of("creditLimit", "1000", "2000"),
                AccountAuditService.FieldChange.of("riskStatus", "NORMAL", "NORMAL"),
                AccountAuditService.FieldChange.of("name", "Old Name", "New Name")
        );

        auditService.recordFieldChanges(
                AccountAuditEntityType.SUPPLIER, "sup-1", changes, "batch update");

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.SUPPLIER, "sup-1");

        // riskStatus skip edildi
        assertThat(history).hasSize(2);
        assertThat(history.stream().map(AccountAuditLog::getFieldName).toList())
                .containsExactlyInAnyOrder("creditLimit", "name");
    }

    @Test
    @Transactional
    @DisplayName("recordCreate tek satır CREATE kaydı yazar")
    void recordCreate_writesSingleRow() {
        auditService.recordCreate(
                AccountAuditEntityType.CUSTOMER, "cust-3", "yeni müşteri formu");

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-3");

        assertThat(history).hasSize(1);
        AccountAuditLog log = history.get(0);
        assertThat(log.getAction()).isEqualTo(AccountAuditAction.CREATE);
        assertThat(log.getFieldName()).isNull();
        assertThat(log.getReason()).isEqualTo("yeni müşteri formu");
    }

    @Test
    @Transactional
    @DisplayName("recordDelete tek satır DELETE kaydı yazar")
    void recordDelete_writesSingleRow() {
        auditService.recordDelete(
                AccountAuditEntityType.CUSTOMER, "cust-4", "kullanıcı talebi");

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-4");

        assertThat(history).hasSize(1);
        assertThat(history.get(0).getAction()).isEqualTo(AccountAuditAction.DELETE);
    }

    @Test
    @Transactional
    @DisplayName("getHistory en yeni üstte sıralı döner")
    void getHistory_orderedDesc() throws InterruptedException {
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-5", "name", "A", "B", null);
        Thread.sleep(10);
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-5", "name", "B", "C", null);
        Thread.sleep(10);
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-5", "name", "C", "D", null);

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-5");

        assertThat(history).hasSize(3);
        // En yeni en üstte: D yeni, A eski
        assertThat(history.get(0).getNewValue()).isEqualTo("D");
        assertThat(history.get(2).getNewValue()).isEqualTo("B");
    }

    @Test
    @Transactional
    @DisplayName("1024 karakteri aşan değer kısaltılarak saklanır")
    void recordFieldChange_truncatesLongValues() {
        String longValue = "x".repeat(2000);
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-6", "notes",
                "old", longValue, null);

        List<AccountAuditLog> history = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "cust-6");

        assertThat(history).hasSize(1);
        assertThat(history.get(0).getNewValue()).hasSize(1024);
    }

    @Test
    @Transactional
    @DisplayName("Farklı entity tipleri çakışmaz")
    void getHistory_segregatesByEntityType() {
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "shared-id", "name", "A", "B", null);
        auditService.recordFieldChange(
                AccountAuditEntityType.SUPPLIER, "shared-id", "name", "X", "Y", null);

        List<AccountAuditLog> custHistory = auditService.getHistory(
                AccountAuditEntityType.CUSTOMER, "shared-id");
        List<AccountAuditLog> supHistory = auditService.getHistory(
                AccountAuditEntityType.SUPPLIER, "shared-id");

        assertThat(custHistory).hasSize(1);
        assertThat(custHistory.get(0).getNewValue()).isEqualTo("B");
        assertThat(supHistory).hasSize(1);
        assertThat(supHistory.get(0).getNewValue()).isEqualTo("Y");
    }

    @Test
    @Transactional
    @DisplayName("Null entityId / fieldName için no-op")
    void recordFieldChange_handlesNullsGracefully() {
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, null, "name", "A", "B", null);
        auditService.recordFieldChange(
                AccountAuditEntityType.CUSTOMER, "cust-7", null, "A", "B", null);

        assertThat(repo.count()).isZero();
    }
}
