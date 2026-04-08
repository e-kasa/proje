package com.sedcore.security.services.imp;

import com.sedcore.security.models.request.CompanyRegistrationRequest;
import com.sedcore.security.repos.*;
import com.sedcore.security.services.ICompanyRegistrationService;
import com.sedcore.security.services.ITokenService;
import com.sedcore.security.services.IUserDefService;
import com.towpen.base.db.model.security.*;
import com.towpen.base.enums.model.AccessType;
import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.UserType;
import com.towpen.base.exceptions.BadRequestException;
import com.towpen.base.security.JWT;
import com.towpen.base.security.model.TOpenSessionInstance;
import com.towpen.utils.PasswordUtil;
import com.towpen.model.PasswordModel;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.*;

@Service
@RequiredArgsConstructor
public class CompanyRegistrationServiceImpl implements ICompanyRegistrationService {

    private final CompanyRepository companyRepository;
    private final UserDefRepository userDefRepository;
    private final UserDefAccessRepository userDefAccessRepository;
    private final UserRoleRepository userRoleRepository;
    private final RoleDefRepository roleDefRepository;
    private final ITokenService tokenService;
    private final UserDefService userDefService;

    @PersistenceContext
    private EntityManager entityManager;

    private static final Long EXPIRE_IN_MINUTES = 60L;
    private static final Long EXPIRE_REFRESH_TOKEN_IN_MINUTES = 120L;

    @Override
    @Transactional
    public JWT registerCompany(CompanyRegistrationRequest request) {
        validateRequest(request);

        String companyCode = generateCompanyCode(request.getCompanyName());

        // 1. Şirket oluştur — persist() kullan (ID Hibernate tarafından üretilir)
        Company company = new Company();
        company.setCompanyCode(companyCode);
        company.setCompanyName(request.getCompanyName());
        company.setSectorType(request.getSectorType());
        company.setIsMainCompany(false);
        if (request.getTaxNumber() != null) company.setTaxNumber(request.getTaxNumber());
        if (request.getTaxOffice() != null) company.setTaxOffice(request.getTaxOffice());
        entityManager.persist(company);

        // 2. Sistem rollerini yeni şirket için kopyala
        List<RoleDef> systemRoles = roleDefRepository.findByIsSystemRoleTrue();
        Map<String, RoleDef> newRolesByCode = new HashMap<>();
        for (RoleDef sysRole : systemRoles) {
            RoleDef newRole = new RoleDef();
            newRole.setName(sysRole.getName() + " - " + companyCode);
            newRole.setDescription(sysRole.getDescription());
            newRole.setCode(sysRole.getCode());
            newRole.setIsActive(true);
            newRole.setIsSystemRole(true);
            newRole.setCompanyCode(companyCode);
            newRole.setCreateTime(new Date());
            newRole.setCreateUser("SYSTEM");
            entityManager.persist(newRole);
            newRolesByCode.put(newRole.getCode(), newRole);
        }

        // 3. Admin kullanıcı oluştur
        UserDef userDef = new UserDef();
        userDef.setUserName(request.getUserName());
        userDef.setUserDisplayName(request.getDisplayName());
        userDef.setCompanyCode(companyCode);
        userDef.setIsActive(true);
        userDef.setLanguageVal(LanguageType.TR);
        userDef.setUserType(UserType.USER);
        userDef.setGenericIdentifier(request.getUserName());
        userDef.setCreateTime(new Date());
        userDef.setCreateUser("SYSTEM");
        entityManager.persist(userDef);

        // 4. Erişim bilgileri (şifre hash)
        PasswordModel pm = PasswordUtil.createHashPassword(request.getPassword());
        UserDefAccess access = new UserDefAccess();
        access.setUserDef(userDef);
        access.setCompanyCode(companyCode);
        access.setCanLogin(true);
        access.setIsForcePasswordChange(false);
        access.setPasswordHash(pm.getPasswordHash());
        access.setSaltKey(pm.getSalt());
        access.setLastChangeTime(new Date());
        access.setHasIpRestriction(false);
        access.setIpRestriction("false");
        access.setAccessType(AccessType.INTERNAL);
        access.setCreateTime(new Date());
        access.setCreateUser("SYSTEM");
        entityManager.persist(access);

        // 5. ADMIN rolü ata
        RoleDef adminRole = newRolesByCode.get("ADMIN");
        if (adminRole == null) {
            throw new BadRequestException("Sistem rolü bulunamadı, lütfen tekrar deneyin");
        }

        UserRole userRole = new UserRole();
        userRole.setRoleDef(adminRole);
        userRole.setUserDef(userDef);
        userRole.setCompanyCode(companyCode);
        userRole.setCreateTime(new Date());
        userRole.setCreateUser("SYSTEM");
        entityManager.persist(userRole);

        entityManager.flush();

        // 6. JWT oluştur ve dön
        TOpenSessionInstance sessionInstance = userDefService.createSessionInstance(userDef);
        return tokenService.createToken(sessionInstance, EXPIRE_IN_MINUTES, EXPIRE_REFRESH_TOKEN_IN_MINUTES);
    }

    private void validateRequest(CompanyRegistrationRequest request) {
        if (request.getCompanyName() == null || request.getCompanyName().isBlank()) {
            throw new BadRequestException("Şirket adı zorunludur");
        }
        if (request.getUserName() == null || request.getUserName().isBlank()) {
            throw new BadRequestException("Kullanıcı adı zorunludur");
        }
        if (request.getPassword() == null || request.getPassword().isBlank()) {
            throw new BadRequestException("Şifre zorunludur");
        }
        if (request.getDisplayName() == null || request.getDisplayName().isBlank()) {
            throw new BadRequestException("Ad Soyad zorunludur");
        }
        if (request.getSectorType() == null || request.getSectorType().isBlank()) {
            throw new BadRequestException("Sektör tipi zorunludur");
        }

        // Kullanıcı adı tekil kontrolü — native query ile tüm şirketlerde arar (Hibernate filter bypass)
        long userCount = userDefRepository.countByUserNameGlobal(request.getUserName());
        if (userCount > 0) {
            throw new BadRequestException("Bu kullanıcı adı zaten kullanılıyor");
        }
    }

    private String generateCompanyCode(String companyName) {
        // Şirket adından max 6 karakter al, uppercase, özel karakter temizle
        String base = companyName.replaceAll("[^a-zA-Z0-9]", "").toUpperCase();
        if (base.length() > 6) base = base.substring(0, 6);
        if (base.isEmpty()) base = "COMP";

        String code = base;
        int suffix = 1;
        while (companyRepository.findByCompanyCode(code).isPresent()) {
            code = base.substring(0, Math.min(base.length(), 6)) + suffix;
            if (code.length() > 8) {
                code = base.substring(0, 8 - String.valueOf(suffix).length()) + suffix;
            }
            suffix++;
        }
        return code;
    }
}
