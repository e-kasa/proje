package com.sedcore.repository;

import com.sedcore.entity.CompanySetting;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CompanySettingRepository extends BaseDaoRepository<CompanySetting> {

    Optional<CompanySetting> findFirstByCompanyCodeOrderByCreateTimeDesc(String companyCode);
}
