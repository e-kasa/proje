package com.sedcore.security.repos;

import com.towpen.base.db.model.security.UserDef;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserDefRepository extends BaseDaoRepository<UserDef> {

    @Query("SELECT u FROM UserDef u WHERE u.userName = :userName")
    Optional<UserDef> findByUserDefName(@Param("userName") String userName);

    /** Şirketin tüm kullanıcılarını isme göre sıralı listele */
    List<UserDef> findAllByCompanyCodeOrderByUserDisplayNameAsc(String companyCode);

    /** Şirketteki aktif kullanıcılar */
    List<UserDef> findAllByCompanyCodeAndIsActiveTrueOrderByUserDisplayNameAsc(String companyCode);

    /**
     * Hibernate company filter'ı bypass ederek kullanıcı adını tüm şirketlerde arar.
     * Şirket kaydında global unique kontrolü için kullanılır.
     */
    @Query(value = "SELECT COUNT(*) FROM user_def WHERE user_name = :userName", nativeQuery = true)
    long countByUserNameGlobal(@Param("userName") String userName);
}
