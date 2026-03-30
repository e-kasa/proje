import { api } from "../core/axiosClient";
import { endpoints } from "../core/endpointBuilder";

export const ProductApi = {
  list: () => api.get(endpoints.products.list()),

  detail: (id: number) =>
      api.get(endpoints.products.detail(id)),

  create: (data:any) =>
      api.post(endpoints.products.create(), data),

  update: (id: number, data:any) =>
      api.put(endpoints.products.update(id), data),

  remove: (id: number) =>
      api.delete(endpoints.products.remove(id)),
};
