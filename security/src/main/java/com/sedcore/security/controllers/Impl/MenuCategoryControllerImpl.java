package com.sedcore.security.controllers.Impl;

import com.sedcore.security.controllers.RestMenuCatigoryController;
import com.sedcore.security.models.model.menu.DtoMenuCategory;
import com.sedcore.security.models.model.menu.DtoMenuCategoryUI;
import com.sedcore.security.services.IMenuCategoryService;
import com.towpen.base.db.model.security.sidebar.MenuCategory;
import com.towpen.base.restservice.model.RestRootEntity;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class MenuCategoryControllerImpl implements RestMenuCatigoryController {

    private final IMenuCategoryService menuCategoryService;

    @Override
    public RestRootEntity<MenuCategory> getMenuCategory() {
        return null;
    }

    @Override
    @PostMapping("/api/save-menu-category")
    public RestRootEntity<List<DtoMenuCategory>> saveMenuCategory( @RequestBody List<DtoMenuCategoryUI> menuCategory) {
        return RestRootEntity.ok(menuCategoryService.saveCategory(menuCategory));
    }

    @Override
    @GetMapping("/api/get-menu-for-user")
    public RestRootEntity<List<DtoMenuCategory>> getMenusForUser() {
        return RestRootEntity.ok(menuCategoryService.getMenusForUser());
    }

}
