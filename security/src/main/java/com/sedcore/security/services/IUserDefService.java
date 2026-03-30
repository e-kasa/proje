package com.sedcore.security.services;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.security.BaseDbService;
import com.towpen.base.security.model.TOpenSessionInstance;

public interface IUserDefService extends BaseDbService<UserDef> {
    TOpenSessionInstance login(String userName, String password);
}
