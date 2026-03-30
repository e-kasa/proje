package com.sedcore.security.repos;

import com.towpen.base.db.model.security.RoleDef;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoleDefRepository extends BaseDaoRepository<RoleDef> {
    @Query("select r from UserRole r where r.userDef.id=:userId")
    List<RoleDef> findByUserDef(String userId);
}
