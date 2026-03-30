package com.sedcore.security.repos;

import com.sedcore.security.queryresult.MenuQueryResult;
import com.towpen.base.db.model.security.sidebar.RoleMenu;
import com.towpen.base.db.repository.BaseDaoRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoleMenuRepository extends BaseDaoRepository<RoleMenu> {
    @Query("select m from RoleMenu m where m.role.id=:id")
    List<RoleMenu> getByRole_Id(String id);
    @Query(value = """
        SELECT
            c.id AS categoryId,
            c.show_sub_route AS showSubRoute,
            c.submenu_hdr AS submenuHdr,
            c.submenu_open AS submenuOpen,
            c.label AS categoryName,

            m.id AS menuId,
            m.label AS menuName,
            m.show_sub_route AS menuShowSubRoute,
            m.submenu AS submenu,
            m.icon AS icon,

            i.id AS itemId,
            i.label AS itemName,
            i.link AS itemPath

        FROM user_def u
        JOIN user_role ur ON ur.user_def_id = u.id
        JOIN role_def r ON ur.role_def_id = r.id
        JOIN role_menu rm ON rm.role_id = r.id
        JOIN menus m ON rm.menu_id = m.id
        JOIN menu_items i ON i.menu_id = m.id
        JOIN menu_categories c ON m.category_id = c.id

        WHERE u.id = :userId
        """, nativeQuery = true)
    List<MenuQueryResult> findMenuStructureByRole(@Param("userId")  String userId);
}
