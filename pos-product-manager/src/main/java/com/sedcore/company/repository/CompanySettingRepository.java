package com.sedcore.company.repository;

import com.sedcore.company.entity.CompanySetting;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CompanySettingRepository extends BaseDaoRepository<CompanySetting> {

    Optional<CompanySetting> findFirstByCompanyCodeOrderByCreateTimeDesc(String companyCode);

    /**
     * Tüm aktif tenant'ların company_code listesi (tekilleştirilmiş).
     *
     * Native query — Hibernate @Filter bypass edilir (scheduled job'ta CompanyContext boş
     * olurken multi-tenant iteration için gerekli). is_active=true & is_cancelled=false
     * filtresi soft-delete kapsamı.
     */
    @Query(value = "SELECT DISTINCT company_code FROM company_setting " +
            "WHERE (is_cancelled = false OR is_cancelled IS NULL) " +
            "ORDER BY company_code",
           nativeQuery = true)
    List<String> findAllActiveCompanyCodes();
}
