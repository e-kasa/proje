package com.sedcore.finance.repository;

import com.sedcore.finance.entity.Expense;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ExpenseRepository extends BaseDaoRepository<Expense> {

    List<Expense> findByCompanyCodeAndIsDeletedFalseOrderByExpenseDateDesc(String companyCode);

    List<Expense> findByCompanyCodeAndCategoryAndIsDeletedFalse(String companyCode, String category);

    List<Expense> findByCompanyCodeAndExpenseDateBetweenAndIsDeletedFalse(
            String companyCode, LocalDateTime start, LocalDateTime end);

    Optional<Expense> findByIdAndCompanyCodeAndIsDeletedFalse(String id, String companyCode);
}
