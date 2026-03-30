import { api } from "../core/axiosClient";

export const AuthService = {
  login: (data: { username: string; password: string }) =>
    api.post("security/authenticate", data),
};
