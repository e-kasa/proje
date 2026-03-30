// src/features/category/services/categoryService.ts

import { api } from '../../../services/core/axiosClient';
import type {
    Category,
    CategoryTree,
    CreateCategoryRequest,
    UpdateCategoryRequest,
    AssignCategoriesToCompanyRequest,
} from '../types/category.types';

// ⭐ Pagination Response Type
interface PageResponse<T> {
    content: T[];
    totalElements: number;
    totalPages: number;
    number: number;
    size: number;
    numberOfElements: number;
    first: boolean;
    last: boolean;
    empty: boolean;
}

class CategoryService {
    private baseUrl = '/api/categories';

    // ========== MERKEZI KATEGORİ YÖNETİMİ (Admin) ==========

    async createCategory(data: CreateCategoryRequest): Promise<Category> {
        return await api.post<Category>(this.baseUrl, data);
    }

    async updateCategory(id: string, data: UpdateCategoryRequest): Promise<Category> {
        return await api.put<Category>(`${this.baseUrl}/${id}`, data);
    }

    async getCategory(id: string): Promise<Category> {
        return await api.get<Category>(`${this.baseUrl}/${id}`);
    }

    async deleteCategory(id: string): Promise<void> {
        return await api.delete(`${this.baseUrl}/${id}`);
    }

    async listCategories(params?: {
        page?: number;
        size?: number;
        sortBy?: string;
        sortDir?: string;
    }): Promise<PageResponse<Category>> {
        return await api.get<PageResponse<Category>>(this.baseUrl, params);
    }

    async searchCategories(
        keyword: string,
        page = 0,
        size = 20
    ): Promise<PageResponse<Category>> {
        return await api.get<PageResponse<Category>>(`${this.baseUrl}/search`, {
            keyword,
            page,
            size,
        });
    }

    async getRootCategories(): Promise<Category[]> {
        return await api.get<Category[]>(`${this.baseUrl}/roots`);
    }

    async getChildCategories(parentId: string): Promise<Category[]> {
        return await api.get<Category[]>(`${this.baseUrl}/${parentId}/children`);
    }

    async getCategoryTree(): Promise<CategoryTree> {
        return await api.get<CategoryTree>(`${this.baseUrl}/tree`);
    }

    // ========== ŞİRKET-KATEGORİ YÖNETİMİ ==========

    async assignCategoriesToCompany(data: AssignCategoriesToCompanyRequest): Promise<void> {
        return await api.post(`${this.baseUrl}/assign-to-company`, data);
    }

    async removeCategoryFromCompany(companyCode: string, categoryId: string): Promise<void> {
        return await api.delete(`${this.baseUrl}/remove-from-company/${companyCode}/${categoryId}`);
    }

    async getCompanyCategories(companyCode: string): Promise<Category[]> {
        return await api.get<Category[]>(`${this.baseUrl}/company/${companyCode}`);
    }

    async getCompanyRootCategories(companyCode: string): Promise<Category[]> {
        return await api.get<Category[]>(`${this.baseUrl}/company/${companyCode}/roots`);
    }

    async getCompanyChildCategories(companyCode: string, parentId: string): Promise<Category[]> {
        return await api.get<Category[]>(
            `${this.baseUrl}/company/${companyCode}/${parentId}/children`
        );
    }

    async getCompanyCategoryTree(companyCode: string): Promise<CategoryTree> {
        return await api.get<CategoryTree>(`${this.baseUrl}/company/${companyCode}/tree`);
    }
}

export const categoryService = new CategoryService();