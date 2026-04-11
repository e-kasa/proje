// src/core/axiosClient/index.ts
// Two separate clients:
//   securityApi  → http://localhost:8000  (authentication)
//   productApi   → http://localhost:8001  (product manager)

import axios, { type AxiosInstance } from "axios";
import { logout, setCredentials } from "../redux/authSlice.ts";
import store from "../redux/store.tsx";

class HttpClient {
    private instance: AxiosInstance;

    constructor(baseURL: string) {
        this.instance = axios.create({
            baseURL,
            timeout: 15000,
        });
        this.requestInterceptor();
        this.responseInterceptor();
    }

    private requestInterceptor() {
        this.instance.interceptors.request.use((config) => {
            const state = store.getState();
            const token = state.auth.token;
            const companyCode = state.auth.companyCode ?? localStorage.getItem("companyCode") ?? "syste";

            if (token) {
                config.headers.Authorization = `Bearer ${token}`;
            }
            config.headers["X-Company-Code"] = companyCode;

            return config;
        });
    }

    private responseInterceptor() {
        this.instance.interceptors.response.use(
            (response) => {
                // Unwrap ApiResponse wrapper automatically
                if (response.data && typeof response.data === "object" && "data" in response.data) {
                    return { ...response, data: response.data.data };
                }
                return response;
            },
            async (error) => {
                if (!error.response) {
                    console.error("❌ Network Error:", error.message);
                    return Promise.reject({
                        message: error.message || "Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.",
                        code: "NETWORK_ERROR",
                    });
                }

                const originalRequest = error.config;

                if (error.response.status === 401 && !originalRequest._retry) {
                    originalRequest._retry = true;
                    try {
                        const res = await axios.post("http://localhost:8000/auth/refresh");
                        const newToken = res.data.accessToken || res.data.token;
                        store.dispatch(setCredentials({ accessToken: newToken, user: null }));
                        originalRequest.headers.Authorization = "Bearer " + newToken;
                        return this.instance(originalRequest);
                    } catch (refreshError) {
                        console.error("❌ Refresh Token Failed:", refreshError);
                        store.dispatch(logout());
                        return Promise.reject({
                            message: "Oturum süreniz doldu. Lütfen tekrar giriş yapın.",
                            code: "TOKEN_EXPIRED",
                        });
                    }
                }

                return Promise.reject(this.handleError(error));
            }
        );
    }

    get = async <T>(url: string, params?: Record<string, unknown>): Promise<T> => {
        const response = await this.instance.get<T>(url, { params });
        return response.data;
    };

    post = async <T>(url: string, data?: unknown): Promise<T> => {
        const response = await this.instance.post<T>(url, data);
        return response.data;
    };

    put = async <T>(url: string, data?: unknown): Promise<T> => {
        const response = await this.instance.put<T>(url, data);
        return response.data;
    };

    delete = async <T = void>(url: string): Promise<T> => {
        const response = await this.instance.delete<T>(url);
        return response.data;
    };

    private handleError(error: unknown) {
        const err = error as { response?: { status: number; data?: { message?: string; error?: string; errorMessage?: string; code?: string } }; message?: string };

        if (!err.response) {
            return {
                message: err.message || "Bağlantı hatası. Sunucuya ulaşılamıyor.",
                code: "NETWORK_ERROR",
                status: 0,
            };
        }

        const status = err.response.status;
        const data = err.response.data;
        const message = data?.message ?? data?.error ?? data?.errorMessage ?? this.getDefaultErrorMessage(status);

        return {
            message,
            status,
            code: data?.code ?? `HTTP_${status}`,
            data,
        };
    }

    private getDefaultErrorMessage(status: number): string {
        const messages: Record<number, string> = {
            400: "Geçersiz istek. Lütfen bilgilerinizi kontrol edin.",
            401: "Oturum süreniz doldu. Lütfen tekrar giriş yapın.",
            403: "Bu işlem için yetkiniz yok.",
            404: "İstenen kaynak bulunamadı.",
            409: "Bu kayıt zaten mevcut.",
            422: "Girilen bilgiler geçersiz.",
            500: "Sunucu hatası. Lütfen daha sonra tekrar deneyin.",
            502: "Sunucu geçici olarak kullanılamıyor.",
            503: "Servis şu anda bakımda.",
        };
        return messages[status] ?? "Bir hata oluştu. Lütfen tekrar deneyin.";
    }
}

// Security service (authentication) → port 8000
export const securityApi = new HttpClient("http://localhost:8000/");

// Product manager service → port 8001
export const productApi = new HttpClient("http://localhost:8001/");

// Default export for backward compatibility (points to product manager)
export const api = productApi;
