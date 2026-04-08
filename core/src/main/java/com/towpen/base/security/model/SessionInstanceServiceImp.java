package com.towpen.base.security.model;

import com.towpen.base.enums.model.LanguageType;
import com.towpen.base.security.ISessionInstanceService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@Component
@Qualifier("sedcoresession")
public class SessionInstanceServiceImp implements ISessionInstanceService {
    @Override
    public boolean isLoggedIn() {
        return getSedcoreJWTAuthToken() != null;
    }

    @Override
    public String getSelectedCompanyCode() {
        return isLoggedIn() ? getSessionInstance().getUserInformation().getSelectedCompanyCode() : null;
    }

    @Override
    public List<TOpenCompanyInfo> getSupportedCompanies() {
        return isLoggedIn() ? getSessionInstance().getUserInformation().getSupportedCompanies(): null;
    }

    @Override
    public String getUserCode() {
        return isLoggedIn() ? getSessionInstance().getUserInformation().getUserName() : null;
    }

    @Override
    public String getUserId() {
        return isLoggedIn() ? getSessionInstance().getUserInformation().getUserId() : null;
    }

    @Override
    public Authentication getAuthentication() {
        return SecurityContextHolder.getContext().getAuthentication();
    }

    @Override
    public TOpenSessionInstance getSessionInstance() {

        TOpenAuthenticationToken token = getSedcoreJWTAuthToken();
        if (token == null || token.getSessionInstance() == null){
            return  null;
        }

        return token.getSessionInstance();
    }

    @Override
    public LanguageType getLanguage() {
        if (isLoggedIn()) {
            TOpenSessionInstance session = getSessionInstance();
            if (session != null && session.getUserInformation() != null
                    && session.getUserInformation().getLanguageVal() != null) {
                return session.getUserInformation().getLanguageVal();
            }
        }
        return LanguageType.TR;
    }

    @Override
    public String getSessionId() {
        return isLoggedIn() ? getSessionInstance().getUserInformation().getSessionId() : null;
    }

    TOpenAuthenticationToken getSedcoreJWTAuthToken(){
        Authentication authentication = getAuthentication();
        if (authentication instanceof  TOpenAuthenticationToken jwtAuthToken){
            return jwtAuthToken;
        }
        return null;
    }
}
