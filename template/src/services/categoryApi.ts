import { api } from "../core/axiosClient";

/**
 * Kategori veri yapısı
 */
export interface CategoryVariant {
  name: string;
  values: string;
}

export interface Category {
  id?: number;
  categoryName: string;
  categorySlug: string;
  description?: string;
  status: boolean;
  variants?: CategoryVariant[];
  createdOn?: string;
}

export interface CategoryCreateRequest {
  categoryName: string;
  categorySlug: string;
  description?: string;
  status: boolean;
  variants?: CategoryVariant[];
}

export interface CategoryUpdateRequest extends CategoryCreateRequest {
  id: number;
}

/**
 * Kategori API servisi
 */
export const CategoryService = {
  /**
   * Tüm kategorileri getir
   */
  getAll: () => api.get<Category[]>("inventory/categories"),

  /**
   * ID'ye göre kategori getir
   */
  getById: (id: number) => api.get<Category>(`inventory/categories/${id}`),

  /**
   * Kategori slug'ına göre kategori getir
   */
  getBySlug: (slug: string) => api.get<Category>(`inventory/categories/slug/${slug}`),

  /**
   * Yeni kategori oluştur
   */
  create: (data: CategoryCreateRequest) => api.post<Category>("inventory/categories", data),

  /**
   * Kategori güncelle
   */
  update: (id: number, data: CategoryUpdateRequest) =>
    api.put<Category>(`inventory/categories/${id}`, data),

  /**
   * Kategori sil
   */
  delete: (id: number) => api.delete(`inventory/categories/${id}`),

  /**
   * Kategorinin varyantlarını getir
   */
  getVariants: (id: number) =>
    api.get<CategoryVariant[]>(`inventory/categories/${id}/variants`),

  /**
   * Kategoriye varyant ekle
   */
  addVariant: (categoryId: number, variant: CategoryVariant) =>
    api.post<CategoryVariant>(`inventory/categories/${categoryId}/variants`, variant),

  /**
   * Kategori varyantını güncelle
   */
  updateVariant: (categoryId: number, variantName: string, variant: CategoryVariant) =>
    api.put<CategoryVariant>(
      `inventory/categories/${categoryId}/variants/${variantName}`,
      variant
    ),

  /**
   * Kategori varyantını sil
   */
  deleteVariant: (categoryId: number, variantName: string) =>
    api.delete(`inventory/categories/${categoryId}/variants/${variantName}`),

  /**
   * Aktif kategorileri getir
   */
  getActive: () => api.get<Category[]>("inventory/categories/active"),

  /**
   * Kategori durumunu değiştir (aktif/pasif)
   */
  toggleStatus: (id: number) =>
    api.put<Category>(`inventory/categories/${id}/toggle-status`, {}),
};
