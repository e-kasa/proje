import { securityApi } from "../core/axiosClient";

export const AuthService = {
  login: (data: { username: string; password: string }) =>
    securityApi.post("security/authenticate", data),
};
