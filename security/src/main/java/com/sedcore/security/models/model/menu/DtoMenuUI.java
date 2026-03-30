package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoCrudModel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@AllArgsConstructor
public class DtoMenuUI extends DtoCrudModel
{
    private String label;
    private String icon;
    private boolean submenu;
    private boolean showSubRoute;
    private List<DtoMenuItemUI> items;
}
