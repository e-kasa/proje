package com.sedcore.security.services.imp;

import com.sedcore.security.models.model.menu.DtoMenu;
import com.sedcore.security.models.model.menu.DtoMenuUI;
import com.sedcore.security.repos.MenuItemRepository;
import com.sedcore.security.services.IMenuItemService;
import com.towpen.base.db.model.security.sidebar.MenuItem;
import com.towpen.base.security.BaseDbServiceImp;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MenuItemServiceImpl extends BaseDbServiceImp<MenuItemRepository, MenuItem> implements IMenuItemService {
    @Override
    public MenuItem saveMenuItem(MenuItem menuItemUi) {
        return save(menuItemUi);
    }

    @Override
    public Class<?> getDTOClassForService() {
        return DtoMenuUI.class;
    }
}
