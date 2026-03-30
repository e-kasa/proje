package com.towpen.base.db.model.security.sidebar;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.towpen.base.db.model.TOpenDbEntity;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "menu_categories")
@Getter @Setter
public class MenuCategory extends TOpenSimpleDbEntity {


    private String label;

    private boolean submenuOpen;
    private boolean showSubRoute;
    private String submenuHdr;

    @OneToMany(mappedBy = "category", cascade = CascadeType.ALL)
    @JsonIgnore
    private List<Menu> menus = new ArrayList<>();

    public MenuCategory(String id,String label, boolean submenuOpen, boolean showSubRoute, String submenuHdr, List<Menu> menus) {
        this.label = label;
        this.submenuOpen = submenuOpen;
        this.showSubRoute = showSubRoute;
        this.submenuHdr = submenuHdr;
        this.menus = menus;
        this.id = id;
    }

    public MenuCategory() {

    }
}

