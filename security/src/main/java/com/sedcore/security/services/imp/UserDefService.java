package com.sedcore.security.services.imp;

import com.sedcore.security.repos.CompanyRepository;
import com.sedcore.security.repos.UserDefAccessRepository;
import com.sedcore.security.repos.UserDefRepository;
import com.sedcore.security.repos.UserRoleRepository;
import com.sedcore.security.services.IUserDefService;
import com.towpen.base.db.model.security.Company;
import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.enums.model.AccessType;
import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.enums.model.TMessageType;
import com.towpen.base.exceptions.TOpenException;
import com.towpen.base.restservice.model.TOpenMessage;
import com.towpen.base.security.BaseDbServiceImp;
import com.towpen.base.security.model.TOpenCompanyInfo;
import com.towpen.base.security.model.TOpenLoginUser;
import com.towpen.base.security.model.TOpenSessionInstance;
import com.towpen.utils.PasswordUtil;
import com.towpen.utils.TStringUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;


@Service
public class UserDefService extends BaseDbServiceImp<UserDefRepository,UserDef> implements IUserDefService {


    @Autowired
    UserDefAccessRepository userDefAccessRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private UserRoleRepository userRoleRepository;

    @Transactional(propagation = Propagation.REQUIRED, noRollbackFor = { TOpenException.class })
    @Override
    public TOpenSessionInstance login(String userName, String password) {
        boolean success = false;
        UserDef userDef = null;
        TOpenException tOpenException = null;
        boolean usernameAndPasswordInValid = TStringUtil.isNull(userName) || TStringUtil.isNull(password);
        String sessionId = null;
        try {

            if (usernameAndPasswordInValid) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_REQUIRED_1009));
            }
            Optional<UserDef> userDefOptional = dao.findByUserDefName(userName);
            if (userDefOptional.isEmpty()) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010));
            }
            userDef = userDefOptional.get();

            Optional<UserDefAccess> userDefAccessOptional = userDefAccessRepository.findByUserDef(userDef);

            if (userDefAccessOptional.isEmpty()) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010));
            }
            UserDefAccess userDefAccess = userDefAccessOptional.get();
            validateUserAccess(userDefAccess);

            boolean passwordValid = validateUserNameAndPassword(password, userDefAccess, userDef);
            if (!passwordValid) {
                throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_PASSWORD_ERROR_1010));
            }
            success = true;

            TOpenSessionInstance sessionInstance = createSessionInstance(userDef);
            sessionId = sessionInstance.getUserInformation().getSessionId();
            return sessionInstance;

        } catch (TOpenException e) {
            success = false;
            tOpenException = e;
            throw e;
        } finally {
            if (!usernameAndPasswordInValid) {

            }
        }
    }
    private void validateUserAccess(UserDefAccess userDefAccess) {
        if (Boolean.FALSE == userDefAccess.getCanLogin()) {
            throw new TOpenException(new TOpenMessage(TMessageType.USERNAME_CANNOT_LOGIN_1011));
        }
        if (Boolean.TRUE == userDefAccess.getHasIpRestriction() && TStringUtil.hasText(userDefAccess.getIpRestriction()) && !checkIpAdress(userDefAccess.getIpRestriction())) {
            throw new TOpenException(new TOpenMessage(TMessageType.DONT_MATCH_IP_ADDRESS_1034));
        }
    }

    private boolean checkIpAdress(String ipAddress) {

        List<String> ipList = Arrays.asList(ipAddress.trim().split(";"));
       // for (String ip : ipList) {
        //    if (getRemoteAddress(httpServletRequest).equals(ip.trim())) {
        //        return true;
        //    }
        //}
        //TODO: create here
        return true;
    }
    private boolean validateUserNameAndPassword(String password,UserDefAccess userDefAccess,UserDef userDef) {
        if (userDefAccess.getAccessType() == AccessType.INTERNAL) {
            return PasswordUtil.isExpectedPassword(password.toCharArray(), userDefAccess.getSaltKey(), userDefAccess.getPasswordHash().toCharArray());
        } else {
            return true;//TODO:ldapService.authenticateReturnBoolean(userDef.getUserName(), password);
        }
    }
    private Optional<UserDef> findByUserName(String userName) {
        return dao.findByUserDefName(userName);
    }


    public TOpenSessionInstance createSessionInstance(UserDef userDef) {
        TOpenLoginUser userSession = createLoginUserInformation(userDef);


        List<String> roles = new ArrayList<>();// role listesini okusun ancak sonra cacheden alacak
        roles.addAll(userRoleRepository.findByUserDef(userDef.getId()));
        Map<String, TOpenCompanyInfo> companies = new HashMap<>();



        Optional<Company> optComp = companyRepository.findByCompanyCode(userDef.getCompanyCode());
        if (optComp.isPresent()) {
            companies.put(optComp.get().getCompanyCode(), new TOpenCompanyInfo(true, optComp.get().getCompanyCode(), optComp.get().getCompanyName()));
        }
//        List<DtoUserDefCompanyAuth> authCompanyList = userCompanyAuthService.findAuthDefListByParams(null, userDef.getId());
//        if (!authCompanyList.isEmpty()) {
//            for (DtoUserDefCompanyAuth item : authCompanyList) {
//                if (companies.computeIfAbsent(item.getCompany().getCompanyCode(), k -> companies.get(item.getCompany().getCompanyCode())) == null) {
//                    companies.put(item.getCompany().getCompanyCode(), new TOpenCompanyInfo(false, item.getCompany().getCompanyCode(), item.getCompany().getCompanyName()));
//                }
//            }
//        }
        String sessionId = java.util.UUID.randomUUID().toString();
        userSession.setSessionId(sessionId);
//		if(userDef.getUserType().isAddIpAddressToToken()) {
//			userSession.setIpAddress(WebUtils.getRemoteAddress(httpServletRequest));
//		}
        userSession.setSupportedCompanies(new ArrayList<>(companies.values()));
        return new TOpenSessionInstance(userSession, roles);
    }


    public TOpenLoginUser createLoginUserInformation(UserDef userDef) {
        TOpenLoginUser loginUser = new TOpenLoginUser();
        loginUser.setSelectedCompanyCode(userDef.getCompanyCode());
        loginUser.setDisplayName(userDef.getUserDisplayName());
        loginUser.setUserId(userDef.getId());
        loginUser.setUserName(userDef.getUserName());
        loginUser.setLanguageVal(LanguageType.getLanguageFromValue(userDef.getLanguageVal() != null ? userDef.getLanguageVal().getValue() : null));

        return loginUser;
    }

    @Override
    public Class<?> getDTOClassForService() {
        return null;
    }
}
