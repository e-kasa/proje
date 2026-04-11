package com.sedcore.repository;

import com.sedcore.entity.Employee;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends BaseDaoRepository<Employee> {

    List<Employee> findByCompanyCodeAndIsDeletedFalseOrderByFirstNameAsc(String companyCode);

    List<Employee> findByCompanyCodeAndDepartmentAndIsDeletedFalse(String companyCode, String department);

    List<Employee> findByCompanyCodeAndStatusAndIsDeletedFalse(String companyCode, String status);

    Optional<Employee> findByIdAndCompanyCodeAndIsDeletedFalse(String id, String companyCode);

    long countByCompanyCodeAndIsDeletedFalse(String companyCode);

    long countByCompanyCodeAndStatusAndIsDeletedFalse(String companyCode, String status);

    List<Employee> findByCompanyCodeAndDepartmentIsNotNullAndIsDeletedFalse(String companyCode);
}
