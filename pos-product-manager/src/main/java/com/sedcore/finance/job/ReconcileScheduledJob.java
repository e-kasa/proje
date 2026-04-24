package com.sedcore.finance.job;

import com.sedcore.common.context.CompanyContext;
import com.sedcore.common.notification.SlackNotifier;
import com.sedcore.company.repository.CompanySettingRepository;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.supplier.service.SupplierAccountService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Nightly drift reconcile job — multi-tenant aware (2026-04-24).
 *
 * Tetikleme: her gece 03:00 (cron = 0 0 3 * * *)
 * Flag: reconcile.scheduled.enabled (default false — "ilk hafta cron.paused=true + manuel gün"
 *        plan riski azaltması gereği). Prod'a çıkışta true yap.
 *
 * <p><b>Multi-tenant flow</b>: {@link CompanySettingRepository#findAllActiveCompanyCodes()}
 * ile tüm aktif tenant kodları native query ile çekilir (Hibernate @Filter bypass).
 * Her tenant için {@link CompanyContext#set(String)} → reconcileAll → {@link CompanyContext#clear()}
 * döngüsü. Bir tenant exception atarsa diğerleri devam eder; aggregate drift bildirimi sonunda.</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ReconcileScheduledJob {

    private final CustomerAccountService customerAccountService;
    private final SupplierAccountService supplierAccountService;
    private final CompanySettingRepository companySettingRepository;
    private final SlackNotifier slackNotifier;

    @Value("${reconcile.scheduled.enabled:false}")
    private boolean enabled;

    @Scheduled(cron = "${reconcile.scheduled.cron:0 0 3 * * *}")
    public void nightlyReconcile() {
        if (!enabled) {
            log.debug("Scheduled reconcile atlandi (reconcile.scheduled.enabled=false)");
            return;
        }

        long start = System.currentTimeMillis();

        List<String> companyCodes;
        try {
            companyCodes = companySettingRepository.findAllActiveCompanyCodes();
        } catch (Exception e) {
            String err = e.getClass().getSimpleName() + ": " + e.getMessage();
            log.error("Nightly reconcile tenant listesi alinamadi: {}", err, e);
            slackNotifier.notify(":x: POS Reconcile — tenant listesi alinamadi: " + err);
            return;
        }

        if (companyCodes == null || companyCodes.isEmpty()) {
            log.warn("Nightly reconcile: tenant bulunamadi");
            return;
        }

        int tenantsProcessed = 0;
        int tenantsFailed = 0;
        int totalCustomerCorrected = 0;
        int totalSupplierCorrected = 0;
        StringBuilder failures = new StringBuilder();

        log.info("Nightly reconcile basladi: tenant sayisi={}", companyCodes.size());

        for (String companyCode : companyCodes) {
            if (companyCode == null || companyCode.isBlank()) continue;
            try {
                CompanyContext.set(companyCode);
                int cust = customerAccountService.reconcileAll();
                int supp = supplierAccountService.reconcileAll();
                totalCustomerCorrected += cust;
                totalSupplierCorrected += supp;
                tenantsProcessed++;
                log.info("Nightly reconcile tenant OK: {} — customers={}, suppliers={}",
                        companyCode, cust, supp);
            } catch (Exception e) {
                tenantsFailed++;
                String err = e.getClass().getSimpleName() + ": " + e.getMessage();
                log.error("Nightly reconcile tenant HATA: {} — {}", companyCode, err, e);
                if (failures.length() > 0) failures.append("; ");
                failures.append(companyCode).append("=").append(err);
            } finally {
                CompanyContext.clear();
            }
        }

        long durationMs = System.currentTimeMillis() - start;
        log.info("Nightly reconcile tamamlandi: tenant OK={}, fail={}, customers={}, suppliers={}, sure={}ms",
                tenantsProcessed, tenantsFailed,
                totalCustomerCorrected, totalSupplierCorrected, durationMs);

        int totalCorrected = totalCustomerCorrected + totalSupplierCorrected;
        if (totalCorrected > 0 || tenantsFailed > 0) {
            String msg = String.format(
                    ":warning: POS Reconcile (nightly) — tenant OK=%d/%d, musteri=%d, tedarikci=%d, sure=%dms%s",
                    tenantsProcessed, companyCodes.size(),
                    totalCustomerCorrected, totalSupplierCorrected, durationMs,
                    tenantsFailed > 0 ? ", HATALAR: " + failures : "");
            slackNotifier.notify(msg);
        }
    }
}
