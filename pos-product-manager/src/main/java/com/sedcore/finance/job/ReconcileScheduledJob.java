package com.sedcore.finance.job;

import com.sedcore.common.notification.SlackNotifier;
import com.sedcore.customer.service.CustomerAccountService;
import com.sedcore.supplier.service.SupplierAccountService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Nightly drift reconcile job.
 *
 * Tetikleme: her gece 03:00 (cron = 0 0 3 * * *)
 * Flag: reconcile.scheduled.enabled (default false — "ilk hafta cron.paused=true + manuel gün"
 *        plan riski azaltması gereği). Prod'a çıkışta true yap.
 *
 * <p><b>Multi-tenant not</b>: Şu anki versiyon Hibernate filter context'i set etmez —
 * scheduled thread'de CompanyContext boş. Filter parametresi null → query tüm tenant'lardan
 * hesap döner. reconcile() yine customer.id bazlı izolasyonla doğru çalışır ama ileride
 * tenant-aware iteration eklenmesi gerekir (CompanyRepository → foreach setContext → reconcileAll).</p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class ReconcileScheduledJob {

    private final CustomerAccountService customerAccountService;
    private final SupplierAccountService supplierAccountService;
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
        int customerCorrected = 0;
        int supplierCorrected = 0;
        String errorMessage = null;

        try {
            log.info("Nightly reconcile basladi");
            customerCorrected = customerAccountService.reconcileAll();
            supplierCorrected = supplierAccountService.reconcileAll();
        } catch (Exception e) {
            errorMessage = e.getClass().getSimpleName() + ": " + e.getMessage();
            log.error("Nightly reconcile exception: {}", errorMessage, e);
        }

        long durationMs = System.currentTimeMillis() - start;
        log.info("Nightly reconcile tamamlandi: customers={}, suppliers={}, sure={}ms, hata={}",
                customerCorrected, supplierCorrected, durationMs, errorMessage);

        int totalCorrected = customerCorrected + supplierCorrected;
        if (totalCorrected > 0 || errorMessage != null) {
            String msg = String.format(
                    ":warning: POS Reconcile (nightly) — musteri=%d, tedarikci=%d, sure=%dms%s",
                    customerCorrected, supplierCorrected, durationMs,
                    errorMessage != null ? ", HATA: " + errorMessage : "");
            slackNotifier.notify(msg);
        }
    }
}
