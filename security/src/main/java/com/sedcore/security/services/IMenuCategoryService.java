package com.sedcore.security.services;

import com.sedcore.security.models.model.menu.DtoMenuCategory;
import com.sedcore.security.models.model.menu.DtoMenuCategoryUI;
import com.towpen.base.db.model.security.sidebar.MenuCategory;
import com.towpen.base.security.BaseDbService;

import java.util.List;

public interface IMenuCategoryService extends BaseDbService<MenuCategory> {

    public List<DtoMenuCategory> saveCategory(List<DtoMenuCategoryUI> menuCategory);

    List<DtoMenuCategory> getMenusForUser();
}
