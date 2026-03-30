package com.sedcore.security.repos;

import com.towpen.base.db.model.security.sidebar.MenuItem;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MenuItemRepository extends BaseDaoRepository<MenuItem> {
}
