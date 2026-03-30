package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserDefAccessRepository extends BaseDaoRepository<UserDefAccess> {
    Optional<UserDefAccess> findByUserDef(UserDef userDef);
}
