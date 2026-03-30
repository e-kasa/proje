package com.sedcore.security.queryresult;

public interface MenuQueryResult {
    String getCategoryId();
    boolean getShowSubRoute();
    String getsubmenuHdr();
    boolean getsubmenuOpen();
    String getCategoryName();
    String getMenuId();
    String getMenuName();

    String getIcon();
    boolean getSubmenu();
    boolean getMenuShowSubRoute();
    String getItemName();
    String getItemPath();
    String getItemId();
}