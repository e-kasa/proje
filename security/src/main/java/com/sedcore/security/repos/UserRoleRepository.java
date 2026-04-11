package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserRole;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRoleRepository extends BaseDaoRepository<UserRole> {

    /** Kullanıcının rol kodlarını döner */
    @Query("SELECT r.roleDef.code FROM UserRole r WHERE r.userDef.id = :userId")
    List<String> findByUserDef(@Param("userId") String userId);

    /** Belirli bir rol koduna sahip UserRole kaydını döner (rol kaldırma için) */
    @Query("SELECT r FROM UserRole r WHERE r.userDef.id = :userId AND r.roleDef.code = :roleCode")
    Optional<UserRole> findByUserDefAndRoleCode(@Param("userId") String userId,
                                                @Param("roleCode") String roleCode);
}

