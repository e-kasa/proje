package com.sedcore.finance.repository;

import com.sedcore.finance.entity.Revenue;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RevenueRepository extends BaseDaoRepository<Revenue> {

    List<Revenue> findByCompanyCodeAndIsDeletedFalseOrderByRevenueDateDesc(String companyCode);

    List<Revenue> findByCompanyCodeAndRevenueDateBetweenAndIsDeletedFalse(
            String companyCode, LocalDateTime start, LocalDateTime end);

    Optional<Revenue> findByIdAndCompanyCodeAndIsDeletedFalse(String id, String companyCode);
}
