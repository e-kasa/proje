package com.sedcore.security.repos;

import com.towpen.base.db.model.system.ExtBundle;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExtBundleRepository extends BaseDaoRepository<ExtBundle> {
    @Query(value = "SELECT * FROM ext_bundles", nativeQuery = true)
    List<ExtBundle> findAllBundles();
}
