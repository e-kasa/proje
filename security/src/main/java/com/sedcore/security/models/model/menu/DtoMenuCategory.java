package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
@Setter
@Getter
@NoArgsConstructor
public class DtoMenuCategory extends DtoBaseModel {
    private String label;
    private boolean submenuOpen;
    private boolean showSubRoute;
    private String submenuHdr;
    private List<DtoMenu> menus;

    public DtoMenuCategory(String label, boolean submenuOpen, boolean showSubRoute, String submenuHdr, List<DtoMenu> menus) {
        this.label = label;
        this.submenuOpen = submenuOpen;
        this.showSubRoute = showSubRoute;
        this.submenuHdr = submenuHdr;
        this.menus = menus;
    }
}
