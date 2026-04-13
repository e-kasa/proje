package com.sedcore.security.services;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.security.BaseDbService;

import java.util.Optional;

public interface IUserDefAccessService extends BaseDbService<UserDefAccess> {
    Optional<UserDefAccess> findFirstByUserDef(UserDef userDef);
}
