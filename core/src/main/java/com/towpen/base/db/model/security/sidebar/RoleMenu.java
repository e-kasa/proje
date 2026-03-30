package com.towpen.base.db.model.security.sidebar;

import com.towpen.base.db.model.TOpenSimpleDbEntity;
import com.towpen.base.db.model.security.RoleDef;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "role_menu")
@Getter @Setter
public class RoleMenu extends TOpenSimpleDbEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id")
    private RoleDef role;

    @ManyToOne(fetch = FetchType.LAZY)
    private Menu menu;
}
