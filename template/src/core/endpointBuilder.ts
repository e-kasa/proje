// src/core/endpointBuilder.ts

export const endpoints = {
    auth: {
        login: () => "/auth/login",
        //refresh: () => "/auth/refresh",
    },
    products: {
        list: () => "/products",
        detail: (id: number) => `/products/${id}`,
        create: () => "/products",
        update: (id: number) => `/products/${id}`,
        remove: (id: number) => `/products/${id}`,
    },
};
