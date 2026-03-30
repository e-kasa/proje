package com.sedcore.security.services.imp;

import com.sedcore.security.models.model.menu.DtoMenu;
import com.sedcore.security.repos.MenuRepository;
import com.sedcore.security.services.IMenuService;
import com.towpen.base.db.model.security.sidebar.Menu;
import com.towpen.base.security.BaseDbServiceImp;
import org.springframework.stereotype.Service;

@Service
public class MenuServiceImpl extends BaseDbServiceImp<MenuRepository, Menu> implements IMenuService {
    @Override
    public Class<?> getDTOClassForService() {
        return DtoMenu.class;
    }
}
