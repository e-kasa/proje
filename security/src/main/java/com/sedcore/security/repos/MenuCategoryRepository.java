package com.sedcore.security.repos;

import com.towpen.base.db.model.security.sidebar.MenuCategory;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuCategoryRepository extends BaseDaoRepository<MenuCategory> {
}
