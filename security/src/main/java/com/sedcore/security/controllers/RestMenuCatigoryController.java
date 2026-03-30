package com.sedcore.security.controllers;

import com.sedcore.security.models.model.menu.DtoMenuCategory;
import com.sedcore.security.models.model.menu.DtoMenuCategoryUI;
import com.towpen.base.db.model.security.sidebar.MenuCategory;
import com.towpen.base.restservice.model.RestRootEntity;

import java.util.List;

public interface RestMenuCatigoryController {
    RestRootEntity<MenuCategory> getMenuCategory();
    RestRootEntity<List<DtoMenuCategory>> saveMenuCategory(List<DtoMenuCategoryUI> menuCategory);
    RestRootEntity<List<DtoMenuCategory>> getMenusForUser();
}
