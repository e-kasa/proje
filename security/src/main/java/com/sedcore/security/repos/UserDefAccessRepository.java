package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserDefAccessRepository extends BaseDaoRepository<UserDefAccess> {
    /** Kullanıcıya ait erişim kaydını döner. Birden fazla kayıt varsa ilkini alır (LIMIT 1). */
    Optional<UserDefAccess> findFirstByUserDefOrderByCreateTimeAsc(UserDef userDef);
}
