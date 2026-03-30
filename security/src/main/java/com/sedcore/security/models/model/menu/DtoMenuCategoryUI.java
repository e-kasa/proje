package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoCrudModel;
import lombok.Data;

import java.util.List;

@Data
public class DtoMenuCategoryUI extends DtoCrudModel {
    private String label;
    private boolean submenuOpen;
    private boolean showSubRoute;
    private String submenuHdr;
    private List<DtoMenuUI> menus;
}
