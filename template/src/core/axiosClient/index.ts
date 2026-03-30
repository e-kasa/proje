// src/services/core/axiosClient.ts

import axios from "axios";
import { logout, setCredentials } from "../redux/authSlice.ts";
import store from "../redux/store.tsx";



export class HttpClient {

    
    private instance = axios.create({
        baseURL: 'http://localhost:8080/',
        timeout: 15000,
    });

    constructor() {
        this.requestInterceptor();
        this.responseInterceptor();
    }

    private requestInterceptor() {
        this.instance.interceptors.request.use((config) => {
            const token = store.getState().auth.token;

            if (token) {
                config.headers.Authorization = `Bearer ${token}`;
            }
            return config;
        });
    }

    private responseInterceptor() {
        this.instance.interceptors.response.use(
            (response) => {
                // ✅ ApiResponse wrapper'ı otomatik aç
                if (response.data && typeof response.data === 'object' && 'data' in response.data) {
                    return {
                        ...response,
                        data: response.data.data, // ApiResponse.data'yı direkt döndür
                    };
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
                        const res = await axios.post(
                            import.meta.env.VITE_API_URL + "/auth/refresh"
                        );

                        const newToken = res.data.accessToken || res.data.token;

                        store.dispatch(
                            setCredentials({ accessToken: newToken, user: null })
                        );

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

                return Promise.reject(error);
            }
        );
    }

    get = async <T>(url: string, params?: any): Promise<T> => {
        const response = await this.instance.get<T>(url, {
            params
        });
        return response.data;
    };


    post = async <T>(url: string, data?: any): Promise<T> => {
        try {
            const response = await this.instance.post<T>(url, data, {
            });
            return response.data;
        } catch (error) {
            throw this.handleError(error);
        }
    };

    put = async <T>(url: string, data?: any): Promise<T> => {
        try {
            const response = await this.instance.put<T>(url, data);
            return response.data;
        } catch (error) {
            throw this.handleError(error);
        }
    };

    delete = async <T = void>(url: string): Promise<T> => {
        try {
            const response = await this.instance.delete<T>(url);
            return response.data;
        } catch (error) {
            throw this.handleError(error);
        }
    };

    private handleError(error: any) {
        if (!error.response) {
            return {
                message: error.message || "Bağlantı hatası. Sunucuya ulaşılamıyor.",
                code: "NETWORK_ERROR",
                status: 0,
            };
        }

        const status = error.response.status;
        const data = error.response.data;

        const message =
            data?.message ||
            data?.error ||
            data?.errorMessage ||
            this.getDefaultErrorMessage(status);

        return {
            message,
            status,
            code: data?.code || `HTTP_${status}`,
            data: data,
            response: error.response,
        };
    }

    private getDefaultErrorMessage(status: number): string {
        switch (status) {
            case 400:
                return "Geçersiz istek. Lütfen bilgilerinizi kontrol edin.";
            case 401:
                return "Oturum süreniz doldu. Lütfen tekrar giriş yapın.";
            case 403:
                return "Bu işlem için yetkiniz yok.";
            case 404:
                return "İstenen kaynak bulunamadı.";
            case 409:
                return "Bu kayıt zaten mevcut.";
            case 422:
                return "Girilen bilgiler geçersiz.";
            case 500:
                return "Sunucu hatası. Lütfen daha sonra tekrar deneyin.";
            case 502:
                return "Sunucu geçici olarak kullanılamıyor.";
            case 503:
                return "Servis şu anda bakımda.";
            default:
                return "Bir hata oluştu. Lütfen tekrar deneyin.";
        }
    }
}

export const api = new HttpClient();