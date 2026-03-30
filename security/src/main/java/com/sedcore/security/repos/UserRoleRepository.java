package com.sedcore.security.repos;

import com.towpen.base.db.model.security.RoleDef;
import com.towpen.base.db.model.security.UserRole;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository

public interface UserRoleRepository extends BaseDaoRepository<UserRole> {
    @Query("select r.roleDef.code from UserRole r where r.userDef.id=:userId")
    List<String> findByUserDef(String userId);
    // UserRole findByName(String name);
}

