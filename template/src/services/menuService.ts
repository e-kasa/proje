import { api } from "../core/axiosClient";

export const MenuService = {
    getMenu: () =>
        api.get("security/api/get-menu-for-user"),
};
