package com.towpen.base.hibernate;

import com.towpen.base.context.TOpenContext;
import com.towpen.base.context.TOpenContextHolder;
import com.towpen.base.security.ISessionInstanceService;
import com.towpen.base.security.model.TOpenCompanyInfo;
import com.towpen.utils.TObjectUtils;
import io.micrometer.common.util.StringUtils;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.hibernate.Session;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Aspect
@Component
public class CompanyFilterInterceptor {
    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private ISessionInstanceService sessionInstanceService;

    @Autowired
    public CompanyFilterInterceptor(EntityManager entityManager, PlatformTransactionManager platformTransactionManager) {
        this.entityManager = entityManager;
    }

    @Before("execution(public * com.towpen.base..repository..find(..))")
    public void beforeFindRepositoryMethod(JoinPoint joinPoint) {
        applyDefaultCompanyFilter();
    }

    @Before("execution(public * com.towpen.base..repository..find*(..))")
    public void beforeFindRepositoryMethodRea(JoinPoint joinPoint) {
        applyDefaultCompanyFilter();
    }

    @Before("execution(public * com.towpen.base..repository..find*(..))")
    public void beforeFindRepositoryMethodRea2(JoinPoint joinPoint) {
        applyDefaultCompanyFilter();
    }

    @Before("execution(public * org.springframework.data.repository..find(..))")
    public void beforeSpringDataFind(JoinPoint joinPoint) {
        applyDefaultCompanyFilter();
    }

    @Before("execution(public * org.springframework.data.repository..find*(..))")
    public void beforeSpringDataFindRea(JoinPoint joinPoint) {
        applyDefaultCompanyFilter();
    }

    @Before("execution(public * org.springframework.data.repository..search(..))")
    public void beforeSpringDataSearh(JoinPoint joinPoint) {
        disableAllCompanyFilter();
    }

    @Before("execution(public * com.towpen.base..repository..search(..))")
    public void beforeSearchRepositoryMethod(JoinPoint joinPoint) {
        disableAllCompanyFilter();
    }

    @Before("execution(public * com.towpen.base..repository..search*(..))")
    public void beforeSearchRepositoryMethodRea2(JoinPoint joinPoint) {
        disableAllCompanyFilter();
    }


    @Before("execution(public * com.towpen.base..repository..search*(..))")
    public void beforeSearchRepositoryMethodForRea(JoinPoint joinPoint) {
        disableAllCompanyFilter();
    }

    @Pointcut("@annotation(com.towpen.base.hibernate.AllSupportedCompany)")
    public void beforeAllSupportedCompanyAnno(JoinPoint joinPoint) {
        applyAllCompanyFilter();
    }

    private List<String> getSupportedCompanyList() {
        List<String> supportedCompanyStrList = new ArrayList<>();
        List<TOpenCompanyInfo> supportedCompanyList = sessionInstanceService.getSupportedCompanies();
        if (TObjectUtils.isEmpty(supportedCompanyList)) {
            supportedCompanyList.forEach(company -> supportedCompanyStrList.add(company.getCode()));
        }
        return supportedCompanyStrList;
    }

    private List<String> getDefaultCompanyList() {
        List<String> defaultCompanyList = new ArrayList<>();
        TOpenContext jsureContext = TOpenContextHolder.getContext();

        if (jsureContext.isUseInCompanyFilter() && StringUtils.isNotBlank(jsureContext.getCompanyCode())) {
            defaultCompanyList.add(jsureContext.getCompanyCode());
        } else if (sessionInstanceService.getSelectedCompanyCode() != null) {
            defaultCompanyList.add(sessionInstanceService.getSelectedCompanyCode());
        }
        return defaultCompanyList;
    }

    private void applyAllCompanyFilter() {
        List<String> companies = getSupportedCompanyList();
        if (entityManager.unwrap(Session.class).getEnabledFilter(CompanyFilterStatics.FILTER_COMPANY) == null && !TObjectUtils.isEmpty(companies)) {
            entityManager.unwrap(Session.class).enableFilter(CompanyFilterStatics.FILTER_COMPANY).setParameterList("cpCode", companies);
        }
    }

    private void disableAllCompanyFilter() {
        entityManager.unwrap(Session.class).disableFilter(CompanyFilterStatics.FILTER_COMPANY);

    }

    private void applyDefaultCompanyFilter() {
        TOpenContext context = TOpenContextHolder.getContext();
        if (context.isDisableCompanyFilter()) {
            disableAllCompanyFilter();
        } else {
            List<String> defaultCompanyList = getDefaultCompanyList();
            if (entityManager.unwrap(Session.class).getEnabledFilter(CompanyFilterStatics.FILTER_COMPANY) == null && !TObjectUtils.isEmpty(defaultCompanyList)) {
                try {
                    entityManager.unwrap(Session.class).enableFilter(CompanyFilterStatics.FILTER_COMPANY).setParameterList("cpCode", defaultCompanyList);
                } catch (Exception e) {
                    log.error(e.getMessage());
                }
            }
        }
    }

    /**
     *  Reset company filter to default company
     */
    public void resetCompanyFilter() {
        disableAllCompanyFilter();
        applyDefaultCompanyFilter();
    }

    public EntityManager getEntityManager() {
        return entityManager;
    }
}
