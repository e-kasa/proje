package com.towpen.base.db.model.security.sidebar;

import com.towpen.base.db.model.TOpenDbEntity;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import com.towpen.base.db.models.BaseDbEntity;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "menus")
@Getter @Setter
public class Menu extends TOpenSimpleDbEntity {


    private String label;
    private String icon;
    private boolean submenu;
    private boolean showSubRoute;

    @ManyToOne
    @JoinColumn(name = "category_id")
    private MenuCategory category;

    @OneToMany(mappedBy = "menu", cascade = CascadeType.ALL)
    private List<MenuItem> items = new ArrayList<>();

    public Menu(String id,String label, String icon, boolean submenu, boolean showSubRoute,  List<MenuItem> items) {
        this.label = label;
        this.icon = icon;
        this.submenu = submenu;
        this.showSubRoute = showSubRoute;
        this.items = items;
        this.id = id;
    }

    public Menu() {

    }
}

