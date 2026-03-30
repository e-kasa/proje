package com.sedcore.security.repos;

import com.towpen.base.db.model.security.sidebar.Menu;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MenuRepository extends BaseDaoRepository<Menu> {
}
