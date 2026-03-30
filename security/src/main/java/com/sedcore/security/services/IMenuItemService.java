package com.sedcore.security.services;

import com.towpen.base.db.model.security.sidebar.MenuItem;
import com.towpen.base.security.BaseDbService;

public interface IMenuItemService extends BaseDbService<MenuItem> {
    public MenuItem saveMenuItem(MenuItem menuItemUi);
}
