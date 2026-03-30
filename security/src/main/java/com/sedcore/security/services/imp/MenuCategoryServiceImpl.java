package com.sedcore.security.services.imp;

import com.sedcore.security.models.model.menu.*;
import com.sedcore.security.queryresult.MenuQueryResult;
import com.sedcore.security.repos.MenuCategoryRepository;
import com.sedcore.security.repos.RoleMenuRepository;
import com.sedcore.security.services.IMenuCategoryService;
import com.sedcore.security.services.IMenuItemService;
import com.sedcore.security.services.IMenuService;
import com.towpen.base.db.model.security.sidebar.Menu;
import com.towpen.base.db.model.security.sidebar.MenuCategory;
import com.towpen.base.db.model.security.sidebar.MenuItem;
import com.towpen.base.restservice.model.DtoBaseModel;
import com.towpen.base.security.BaseDbServiceImp;
import com.towpen.base.security.ISessionInstanceService;
import com.towpen.base.security.model.TOpenSessionInstance;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class MenuCategoryServiceImpl extends BaseDbServiceImp<MenuCategoryRepository, MenuCategory> implements IMenuCategoryService {


    private final MenuCategoryRepository menuCategoryRepository;
    private final RoleMenuRepository roleMenuRepository;

    @Override
    public Class<?> getDTOClassForService() {
        return DtoMenuCategory.class;
    }


        private final ISessionInstanceService sessionInstanceService;
    private final IMenuService menuService;
        private final IMenuItemService menuItemService;

    @Transactional
    public List<DtoMenuCategory> saveCategory(List<DtoMenuCategoryUI> dtoList) {

        List<DtoMenuCategory> result = new ArrayList<>();

        for (DtoMenuCategoryUI dto : dtoList) {

            // --- Category ---
            MenuCategory category = new MenuCategory();
            category.setLabel(dto.getLabel());
            category.setSubmenuOpen(dto.isSubmenuOpen());
            category.setShowSubRoute(dto.isShowSubRoute());
            category.setSubmenuHdr(dto.getSubmenuHdr());

            List<Menu> menuEntities = new ArrayList<>();

            // --- Menus ---
            if (dto.getMenus() != null) {
                for (DtoMenuUI menuUI : dto.getMenus()) {

                    Menu menu = new Menu();
                    menu.setLabel(menuUI.getLabel());
                    menu.setIcon(menuUI.getIcon());
                    menu.setSubmenu(menuUI.isSubmenu());
                    menu.setShowSubRoute(menuUI.isShowSubRoute());
                    menu.setCategory(category);

                    List<MenuItem> items = new ArrayList<>();

                    // --- Menu Items ---
                    if (menuUI.getItems() != null) {
                        for (DtoMenuItemUI itemUI : menuUI.getItems()) {

                            MenuItem item = new MenuItem();
                            item.setLabel(itemUI.getLabel());
                            item.setLink(itemUI.getLink());
                            item.setMenu(menu);

                            items.add(menuItemService.save(item));
                        }
                    }

                    menu.setItems(items);

                    menuEntities.add(menuService.save(menu));
                }
            }

            category.setMenus(menuEntities);

            // Cascade ALL: category kaydedince menüler de kaydedilir
            MenuCategory saved = save(category);

            // DTO'ya dönüştür
            result.add(toDto(saved));
        }

        return result;
    }

    @Override
    public List<DtoMenuCategory> getMenusForUser() {
        TOpenSessionInstance session = sessionInstanceService.getSessionInstance();
        if (session == null || session.getRoles() == null) {
            return Collections.emptyList();
        }
            List<MenuQueryResult> rows = roleMenuRepository.findMenuStructureByRole(session.getUserInformation().getUserId());

            Map<String, MenuCategory> categoryMap = new LinkedHashMap<>();
            Map<String, Menu> menuMap = new LinkedHashMap<>();

            for (MenuQueryResult row : rows) {

                // CATEGORY
                categoryMap.putIfAbsent(row.getCategoryId(),
                        new MenuCategory(row.getCategoryId(), row.getCategoryName(),row.getsubmenuOpen(),row.getShowSubRoute(),row.getsubmenuHdr(), new ArrayList<Menu>()));

                MenuCategory category = categoryMap.get(row.getCategoryId());

                // MENU
                menuMap.putIfAbsent(row.getMenuId(),
                        new Menu(row.getMenuId(), row.getMenuName(),row.getIcon(),row.getSubmenu(),row.getMenuShowSubRoute(), new ArrayList<MenuItem>()));

                Menu menu = menuMap.get(row.getMenuId());

                // CATEGORY → MENU ekle (bir kere)
                if (!category.getMenus().contains(menu)) {
                    category.getMenus().add(menu);
                }

                // ITEM
                menu.getItems().add(
                        new MenuItem(
                                row.getItemId(),
                                row.getItemName(),
                                row.getItemPath()
                        )
                );
            }

        return toDtoList(new ArrayList<>(categoryMap.values()));
        }

    private DtoMenuCategory toDto(MenuCategory category) {

        DtoMenuCategory dto = new DtoMenuCategory();
        dto.setLabel(category.getLabel());
        dto.setSubmenuOpen(category.isSubmenuOpen());
        dto.setShowSubRoute(category.isShowSubRoute());
        dto.setSubmenuHdr(category.getSubmenuHdr());

        List<DtoMenu> menuDTOs = category.getMenus()
                .stream()
                .map(menu -> {
                    DtoMenu m = new DtoMenu();
                    m.setLabel(menu.getLabel());
                    m.setIcon(menu.getIcon());
                    m.setSubmenu(menu.isSubmenu());
                    m.setShowSubRoute(menu.isShowSubRoute());

                    List<DtoMenuItem> itemDTOs = menu.getItems()
                            .stream()
                            .map(item -> {
                                DtoMenuItem i = new DtoMenuItem();
                                i.setLabel(item.getLabel());
                                i.setLink(item.getLink());
                                return i;
                            })
                            .toList();

                    m.setItems(itemDTOs);
                    return m;
                })
                .toList();

        dto.setMenus(menuDTOs);

        return dto;
    }
    private List<DtoMenuCategory> toDtoList(List<MenuCategory> categories) {
        return categories.stream()
                .map(this::toDto)   // Zaten elinde tekli çevirici var
                .toList();
    }
}
