package com.sedcore.security.services.imp;

import com.sedcore.security.models.request.*;
import com.sedcore.security.models.response.UserResponse;
import com.sedcore.security.repos.*;
import com.sedcore.security.services.IUserDefService;
import com.towpen.base.db.model.security.*;
import com.towpen.base.enums.model.*;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.towpen.base.security.BaseDbServiceImp;
import com.towpen.base.security.model.TOpenCompanyInfo;
import com.towpen.base.security.model.TOpenLoginUser;
import com.towpen.base.security.model.TOpenSessionInstance;
import com.towpen.model.PasswordModel;
import com.towpen.utils.PasswordUtil;
import com.towpen.utils.TStringUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class UserDefService extends BaseDbServiceImp<UserDefRepository, UserDef>
        implements IUserDefService {

    @Autowired private UserDefAccessRepository userDefAccessRepository;
    @Autowired private CompanyRepository       companyRepository;
    @Autowired private UserRoleRepository      userRoleRepository;
    @Autowired private RoleDefRepository       roleDefRepository;
    @Autowired private JdbcTemplate            jdbcTemplate;

    // =========================================================================
    // AUTH
    // =========================================================================

    @Transactional
    @Override
    public TOpenSessionInstance login(String userName, String password) {
        boolean success = false;
        boolean usernameAndPasswordInValid = TStringUtil.isNull(userName) || TStringUtil.isNull(password);
        try {
            if (usernameAndPasswordInValid) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_REQUIRED_1009));
            }

            UserDef userDef = dao.findByUserDefName(userName)
                    .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010)));

            UserDefAccess access = userDefAccessRepository.findByUserDef(userDef)
                    .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010)));

            validateUserAccess(access);

            if (!validatePassword(password, access)) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010));
            }

            success = true;
            TOpenSessionInstance session = createSessionInstance(userDef);
            log.info("Login başarılı: user={}", userName);
            return session;

        } catch (TOpenException e) {
            throw e;
        } finally {
            if (!usernameAndPasswordInValid) {
                log.info("Login girişimi: user={}, sonuç={}", userName, success ? "BAŞARILI" : "BAŞARISIZ");
            }
        }
    }

    // =========================================================================
    // LISTELEME
    // =========================================================================

    @Transactional(readOnly = true)
    @Override
    public List<UserResponse> getAllUsers(String companyCode) {
        return dao.findAllByCompanyCodeOrderByUserDisplayNameAsc(companyCode)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    @Override
    public UserResponse getUserById(String userId) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        return toResponse(user);
    }

    // =========================================================================
    // CRUD
    // =========================================================================

    @Transactional
    @Override
    public UserResponse createUser(String companyCode, CreateUserRequest request) {
        // Kullanıcı adı tekil kontrolü
        if (dao.countByUserNameGlobal(request.userName()) > 0) {
            throw new TOpenException(new TOpenMessage(TMessageType.ALREADY_EXISTS_1004));
        }

        UserDef user = new UserDef();
        user.setUserName(request.userName());
        user.setUserDisplayName(request.displayName());
        user.setCompanyCode(companyCode);
        user.setIsActive(true);
        user.setLanguageVal(parseLanguage(request.languageVal()));
        user.setUserType(parseUserType(request.userType()));
        user.setGenericIdentifier(request.userName());
        user.setStoreId(request.storeId());
        user.setCreateTime(new Date());
        user.setCreateUser("SYSTEM");

        UserDef saved = save(user);

        // Erişim / şifre kaydı
        PasswordModel pm = PasswordUtil.createHashPassword(request.password());
        UserDefAccess access = new UserDefAccess();
        access.setUserDef(saved);
        access.setCompanyCode(companyCode);
        access.setCanLogin(true);
        access.setIsForcePasswordChange(false);
        access.setPasswordHash(pm.getPasswordHash());
        access.setSaltKey(pm.getSalt());
        access.setLastChangeTime(new Date());
        access.setHasIpRestriction(false);
        access.setIpRestriction("");
        access.setAccessType(AccessType.INTERNAL);
        access.setCreateTime(new Date());
        access.setCreateUser("SYSTEM");
        userDefAccessRepository.save(access);

        // Rol atamaları
        if (request.roles() != null) {
            for (String roleCode : request.roles()) {
                assignRoleInternal(saved, roleCode, companyCode);
            }
        }

        log.info("Kullanıcı oluşturuldu: {} ({})", saved.getUserName(), saved.getId());
        return toResponse(saved);
    }

    @Transactional
    @Override
    public UserResponse updateUser(String userId, UpdateUserRequest request) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        if (request.displayName() != null && !request.displayName().isBlank()) {
            user.setUserDisplayName(request.displayName());
        }
        if (request.languageVal() != null) {
            user.setLanguageVal(parseLanguage(request.languageVal()));
        }
        if (request.storeId() != null) {
            user.setStoreId(request.storeId().isBlank() ? null : request.storeId());
        }
        if (request.userType() != null) {
            user.setUserType(parseUserType(request.userType()));
        }

        UserDef saved = save(user);
        log.info("Kullanıcı güncellendi: {}", saved.getUserName());
        return toResponse(saved);
    }

    @Transactional
    @Override
    public void deleteUser(String userId) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));
        user.setIsActive(false);
        save(user);
        log.info("Kullanıcı silindi (soft): {}", user.getUserName());
    }

    @Transactional
    @Override
    public void toggleStatus(String userId) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        boolean newStatus = !Boolean.TRUE.equals(user.getIsActive());
        user.setIsActive(newStatus);

        // UserDefAccess.canLogin'i de senkronize et
        userDefAccessRepository.findByUserDef(user).ifPresent(access -> {
            access.setCanLogin(newStatus);
            userDefAccessRepository.save(access);
        });

        save(user);
        log.info("Kullanıcı durumu değiştirildi: {} → {}", user.getUserName(), newStatus ? "AKTİF" : "PASİF");
    }

    // =========================================================================
    // ŞİFRE
    // =========================================================================

    @Transactional
    @Override
    public void changePassword(String userId, ChangePasswordRequest request) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        UserDefAccess access = userDefAccessRepository.findByUserDef(user)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        // Mevcut şifreyi doğrula
        if (!PasswordUtil.isExpectedPassword(
                request.currentPassword().toCharArray(),
                access.getSaltKey(),
                access.getPasswordHash().toCharArray())) {
            throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010));
        }

        updatePasswordHash(access, request.newPassword());
        log.info("Şifre değiştirildi: {}", user.getUserName());
    }

    @Transactional
    @Override
    public void resetPassword(String userId, ResetPasswordRequest request) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        UserDefAccess access = userDefAccessRepository.findByUserDef(user)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        updatePasswordHash(access, request.newPassword());
        access.setIsForcePasswordChange(true); // Sonraki girişte şifre değiştirme zorunlu
        userDefAccessRepository.save(access);
        log.info("Şifre sıfırlandı (admin): {}", user.getUserName());
    }

    // =========================================================================
    // ROL
    // =========================================================================

    @Transactional
    @Override
    public void assignRole(String userId, String roleCode, String companyCode) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        // Aynı rol zaten atanmışsa tekrar atama
        boolean alreadyAssigned = userRoleRepository.findByUserDef(userId)
                .stream()
                .anyMatch(r -> r.equalsIgnoreCase(roleCode));
        if (alreadyAssigned) {
            log.warn("Rol zaten atanmış: user={}, role={}", user.getUserName(), roleCode);
            return;
        }

        assignRoleInternal(user, roleCode, companyCode);
        log.info("Rol atandı: user={}, role={}", user.getUserName(), roleCode);
    }

    @Transactional
    @Override
    public void removeRole(String userId, String roleCode) {
        UserDef user = dao.findById(userId)
                .orElseThrow(() -> new TOpenException(new TOpenMessage(TMessageType.NOT_EXISTS_IN_THE_RECORDS_1006)));

        userRoleRepository.findByUserDefAndRoleCode(userId, roleCode).ifPresent(userRole -> {
            userRoleRepository.delete(userRole);
            log.info("Rol kaldırıldı: user={}, role={}", user.getUserName(), roleCode);
        });
    }

    @Transactional(readOnly = true)
    @Override
    public List<String> getRoles(String userId) {
        return userRoleRepository.findByUserDef(userId);
    }

    // =========================================================================
    // SESSION INSTANCE (login + company registration için)
    // =========================================================================

    public TOpenSessionInstance createSessionInstance(UserDef userDef) {
        TOpenLoginUser userSession = createLoginUserInformation(userDef);

        List<String> roles = new ArrayList<>(userRoleRepository.findByUserDef(userDef.getId()));
        Map<String, TOpenCompanyInfo> companies = new HashMap<>();

        companyRepository.findByCompanyCode(userDef.getCompanyCode()).ifPresent(company ->
                companies.put(company.getCompanyCode(),
                        new TOpenCompanyInfo(true, company.getCompanyCode(), company.getCompanyName()))
        );

        String sessionId = UUID.randomUUID().toString();
        userSession.setSessionId(sessionId);
        userSession.setSupportedCompanies(new ArrayList<>(companies.values()));

        return new TOpenSessionInstance(userSession, roles);
    }

    public TOpenLoginUser createLoginUserInformation(UserDef userDef) {
        TOpenLoginUser loginUser = new TOpenLoginUser();
        loginUser.setSelectedCompanyCode(userDef.getCompanyCode());
        loginUser.setDisplayName(userDef.getUserDisplayName());
        loginUser.setUserId(userDef.getId());
        loginUser.setUserName(userDef.getUserName());
        loginUser.setLanguageVal(LanguageType.getLanguageFromValue(
                userDef.getLanguageVal() != null ? userDef.getLanguageVal().getValue() : null));

        HashMap<String, Object> dynamicParams = new HashMap<>();

        // Sektör tipi
        companyRepository.findByCompanyCode(userDef.getCompanyCode()).ifPresent(company -> {
            if (company.getSectorType() != null) {
                dynamicParams.put("sectorType", company.getSectorType());
            }
        });

        // store_id
        if (userDef.getStoreId() != null && !userDef.getStoreId().isBlank()) {
            dynamicParams.put("storeId", userDef.getStoreId());
        } else {
            try {
                String storeId = jdbcTemplate.queryForObject(
                        "SELECT store_id FROM user_def WHERE id = ?", String.class, userDef.getId());
                if (storeId != null && !storeId.isBlank()) {
                    dynamicParams.put("storeId", storeId);
                }
            } catch (Exception ignored) {}
        }

        if (!dynamicParams.isEmpty()) {
            loginUser.setDynamicLoginParameters(dynamicParams);
        }

        return loginUser;
    }

    // =========================================================================
    // YARDIMCI
    // =========================================================================

    @Override
    public Class<?> getDTOClassForService() {
        return UserResponse.class;
    }

    private void validateUserAccess(UserDefAccess access) {
        if (!Boolean.TRUE.equals(access.getCanLogin())) {
            throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_CANNOT_LOGIN_1011));
        }
        if (Boolean.TRUE.equals(access.getHasIpRestriction())
                && TStringUtil.hasText(access.getIpRestriction())
                && !checkIpAddress(access.getIpRestriction())) {
            throw new TOpenException(new TOpenMessage(TMessageType.DONT_MATCH_IP_ADDRESS_1034));
        }
    }

    /**
     * IP kısıtlama kontrolü.
     * IP listesi noktalı virgülle ayrılmış: "192.168.1.1;10.0.0.5"
     * Şu an her IP'e izin verilir (LDAP/proxy ortamı için gerçek IP tespiti eklenebilir).
     */
    private boolean checkIpAddress(String allowedIps) {
        // TODO: javax.servlet.http.HttpServletRequest inject edilerek
        //       request.getRemoteAddr() ile karşılaştırılabilir.
        //       Spring Boot 3 + virtual threads ile RequestContextHolder.getRequestAttributes()
        //       kullanımı güvenlidir.
        return true;
    }

    private boolean validatePassword(String rawPassword, UserDefAccess access) {
        return switch (access.getAccessType()) {
            case INTERNAL -> PasswordUtil.isExpectedPassword(
                    rawPassword.toCharArray(),
                    access.getSaltKey(),
                    access.getPasswordHash().toCharArray());
            default -> true; // LDAP / SSO — harici doğrulama
        };
    }

    private void updatePasswordHash(UserDefAccess access, String newPassword) {
        PasswordModel pm = PasswordUtil.createHashPassword(newPassword);
        access.setPasswordHash(pm.getPasswordHash());
        access.setSaltKey(pm.getSalt());
        access.setLastChangeTime(new Date());
        userDefAccessRepository.save(access);
    }

    private void assignRoleInternal(UserDef user, String roleCode, String companyCode) {
        roleDefRepository.findByCodeAndCompanyCode(roleCode, companyCode).ifPresentOrElse(
                role -> {
                    UserRole userRole = new UserRole();
                    userRole.setRoleDef(role);
                    userRole.setUserDef(user);
                    userRole.setCompanyCode(companyCode);
                    userRole.setCreateTime(new Date());
                    userRole.setCreateUser("SYSTEM");
                    userRoleRepository.save(userRole);
                },
                () -> log.warn("Rol bulunamadı, atlanamadı: roleCode={}, company={}", roleCode, companyCode)
        );
    }

    private UserResponse toResponse(UserDef user) {
        // toDTO(): id, companyCode, isActive, storeId, userName → BeanUtils ile kopyalanır
        UserResponse dto = toDTO(user);

        // displayName — entity'de userDisplayName olarak tanımlı, isim uyuşmazlığı
        dto.setDisplayName(user.getUserDisplayName());

        // languageVal — entity'de LanguageType enum, response'da String
        dto.setLanguageVal(user.getLanguageVal() != null ? user.getLanguageVal().getValue() : "TR");

        // userType — entity'de UserType enum, response'da String
        dto.setUserType(user.getUserType() != null ? user.getUserType().name() : "USER");

        // canLogin — UserDef'te değil, UserDefAccess'ten gelir
        Boolean canLogin = userDefAccessRepository.findByUserDef(user)
                .map(UserDefAccess::getCanLogin)
                .orElse(false);
        dto.setCanLogin(canLogin);

        // roles — UserRole ilişkisinden gelir
        dto.setRoles(userRoleRepository.findByUserDef(user.getId()));

        return dto;
    }

    private LanguageType parseLanguage(String val) {
        if (val == null) return LanguageType.TR;
        return switch (val.toUpperCase()) {
            case "EN" -> LanguageType.EN;
            default   -> LanguageType.TR;
        };
    }

    private com.towpen.base.enums.model.UserType parseUserType(String val) {
        if (val == null) return com.towpen.base.enums.model.UserType.USER;
        try {
            return com.towpen.base.enums.model.UserType.valueOf(val.toUpperCase());
        } catch (IllegalArgumentException e) {
            return com.towpen.base.enums.model.UserType.USER;
        }
    }
}
