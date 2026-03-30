package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserDefRepository extends BaseDaoRepository<UserDef> {
    @Query("select n from UserDef n where n.userName =:userName")
    Optional<UserDef> findByUserDefName(@Param("userName") String userName);

}
