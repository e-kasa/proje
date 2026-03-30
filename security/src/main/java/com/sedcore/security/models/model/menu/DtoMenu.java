package com.sedcore.security.models.model.menu;

import com.towpen.base.restservice.model.DtoBaseModel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class DtoMenu extends DtoBaseModel
{
    private String label;
    private String icon;
    private boolean submenu;
    private boolean showSubRoute;
    private List<DtoMenuItem> items;
}
