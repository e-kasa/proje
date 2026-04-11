package com.sedcore.common.filter;

import com.sedcore.common.context.CompanyContext;
import com.towpen.base.hibernate.CompanyFilterStatics;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.hibernate.Session;
import org.springframework.stereotype.Component;

/**
 * Tüm @Service metodlarından önce çalışarak Hibernate'in
 * company_code filtrini aktif eder.
 *
 * TOpenSimpleCompanyEntity üzerinde tanımlı @FilterDef:
 *   filterCompany → company_code in (:cpCode)
 *
 * CompanyContext'te company_code varsa filtre aktif edilir.
 * Yoksa (örn. internal job, migration) filtre açılmaz ve
 * tüm şirketlerin verisi görünür — dikkatli kullanılmalıdır.
 *
 * NOT: @EnableAspectJAutoProxy bean'inin Spring context'te
 * bulunması gerekir (genellikle @SpringBootApplication ile gelir).
 */
@Slf4j
@Aspect
@Component
@RequiredArgsConstructor
public class CompanyHibernateFilterActivator {

    private final EntityManager entityManager;

    /**
     * com.sedcore.service paketindeki tüm public metodları yakalar.
     * İhtiyaca göre paket adı değiştirilebilir.
     */
    @Around("execution(public * com.sedcore.service..*(..))")
    public Object applyCompanyFilter(ProceedingJoinPoint joinPoint) throws Throwable {
        String companyCode = CompanyContext.get();

        Session session = entityManager.unwrap(Session.class);

        if (companyCode != null && !companyCode.isBlank()) {
            try {
                session.enableFilter(CompanyFilterStatics.FILTER_COMPANY)
                        .setParameter("cpCode", companyCode);
                log.debug("Hibernate company filtresi aktif: {} | method: {}",
                        companyCode, joinPoint.getSignature().getName());
            } catch (Exception e) {
                // Filter zaten aktifse veya tanımlı değilse devam et
                log.warn("Hibernate filter aktif edilemedi: {}", e.getMessage());
            }
        } else {
            log.debug("CompanyContext boş – Hibernate filtresi aktif edilmedi: {}",
                    joinPoint.getSignature().getName());
        }

        try {
            return joinPoint.proceed();
        } finally {
            // Her koşulda filreyi kapat (session pool temizliği)
            try {
                session.disableFilter(CompanyFilterStatics.FILTER_COMPANY);
            } catch (Exception ignored) {}
        }
    }
}
