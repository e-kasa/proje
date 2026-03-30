package com.sedcore.security.repos;

import com.towpen.base.db.model.security.Company;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface CompanyRepository  extends BaseDaoRepository<Company> {

    Optional<Company> findByCompanyCode(String companyCode);

    @Query("select n from Company n where n.isMainCompany = false")
    List<Company> findCompanyListNotMain();

    List<Company> findAll();
}
