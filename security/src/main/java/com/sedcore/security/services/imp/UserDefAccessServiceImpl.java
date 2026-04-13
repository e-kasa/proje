package com.sedcore.security.services.imp;

import com.sedcore.security.repos.UserDefAccessRepository;
import com.sedcore.security.services.IUserDefAccessService;
import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.security.BaseDbServiceImp;
import org.springframework.stereotype.Service;

import java.util.Optional;
@Service
public class UserDefAccessServiceImpl extends BaseDbServiceImp<UserDefAccessRepository,UserDefAccess> implements IUserDefAccessService {
    @Override
    public Optional<UserDefAccess> findFirstByUserDef(UserDef userDef) {
        return dao.findFirstByUserDefOrderByCreateTimeAsc(userDef);
    }

    @Override
    public Optional<UserDefAccess> findByUserDefAndCompanyCode(UserDef userDef, String companyCode) {
        return dao.findByUserDefAndCompanyCode(userDef, companyCode);
    }

    @Override
    public Class<?> getDTOClassForService() {
        return null;
    }
}
