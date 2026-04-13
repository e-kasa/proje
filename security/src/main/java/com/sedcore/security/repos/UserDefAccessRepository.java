package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.model.security.UserDefAccess;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserDefAccessRepository extends BaseDaoRepository<UserDefAccess> {
    /** Kullanıcının belirli bir firmadaki erişim kaydını döner (user_def_id + company_code unique). */
    Optional<UserDefAccess> findByUserDefAndCompanyCode(UserDef userDef, String companyCode);

    /** Fallback: şirketten bağımsız ilk kaydı döner (login akışı için). */
    Optional<UserDefAccess> findFirstByUserDefOrderByCreateTimeAsc(UserDef userDef);
}
