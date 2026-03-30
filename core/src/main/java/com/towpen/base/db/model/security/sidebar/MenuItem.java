package com.towpen.base.db.model.security.sidebar;

import com.towpen.base.db.model.TOpenDbEntity;
import com.towpen.base.db.model.TOpenSimpleDbEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "menu_items")
@Getter
@Setter
public class MenuItem extends TOpenSimpleDbEntity {
    private String label;
    private String link;

    @ManyToOne
    @JoinColumn(name = "menu_id")
    private Menu menu;

    public MenuItem(String itemId, String itemName, String itemPath) {
        this.id = itemId;
        this.label = itemName;
        this.link = itemPath;
    }

    public MenuItem() {

    }
}
