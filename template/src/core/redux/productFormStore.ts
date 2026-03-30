// src/store/productFormStore.ts
import { create } from 'zustand';

export interface Variant {
    sku: string;
    name: string;
    additionalPrice: number;
    attributes: Record<string, string>;
    inventory?: {
        warehouseCode: string;
        physicalQuantity: number;
        minStockLevel?: number;
        reorderPoint?: number;
        maxStockLevel?: number;
        location?: string;
    };
    barcodes?: Array<{
        barcodeCode: string;
        barcodeType: string;
        isPrimary: boolean;
    }>;
}

export interface ProductImage {
    id: string;
    file: File;
    preview: string;
    isPrimary: boolean;
}

interface ProductFormStore {
    productName: string;
    slug: string;
    categoryId: string;
    brand: string;
    basePrice: number;
    description: string;
    variants: Variant[];
    images: ProductImage[];

    setProductName: (name: string) => void;
    setSlug: (slug: string) => void;
    setCategoryId: (id: string) => void;
    setBrand: (brand: string) => void;
    setBasePrice: (price: number) => void;
    setDescription: (desc: string) => void;
    generateVariants: (attributes: Record<string, string[]>) => void;
    addImages: (files: File[]) => void;
    removeImage: (id: string) => void;
    setPrimaryImage: (id: string) => void;
    reset: () => void;
}

export const useProductFormStore = create<ProductFormStore>((set) => ({
    productName: '',
    slug: '',
    categoryId: '',
    brand: '',
    basePrice: 0,
    description: '',
    variants: [],
    images: [],

    setProductName: (name) => {
        const slug = name
            .toLowerCase()
            .trim()
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .replace(/^-|-$/g, '');
        set({ productName: name, slug });
    },

    setSlug: (slug) => set({ slug }),
    setCategoryId: (id) => set({ categoryId: id }),
    setBrand: (brand) => set({ brand }),
    setBasePrice: (price) => set({ basePrice: price }),
    setDescription: (desc) => set({ description: desc }),

    generateVariants: (attributeValues) => {
        const keys = Object.keys(attributeValues);
        const values = keys.map((k) => attributeValues[k]);

        if (keys.length === 0) {
            set({ variants: [] });
            return;
        }

        const cartesian = (...arrays: string[][]): string[][] => {
            if (arrays.length === 0) return [[]];
            if (arrays.length === 1) return arrays[0].map((item) => [item]);
            const [first, ...rest] = arrays;
            const restProduct = cartesian(...rest);
            return first.flatMap((item) =>
                restProduct.map((combination) => [item, ...combination])
            );
        };

        const combinations = cartesian(...values);

        const variants: Variant[] = combinations.map((combo) => {
            const attrs: Record<string, string> = {};
            combo.forEach((value, i) => {
                attrs[keys[i]] = value;
            });

            const skuParts = Object.values(attrs)
                .map((v) => v.substring(0, 3).toUpperCase().replace(/[^A-Z0-9]/g, ''));
            const sku = `PROD-${skuParts.join('-')}-${Date.now().toString().slice(-4)}`;
            const name = Object.values(attrs).join(' - ');

            return {
                sku,
                name,
                additionalPrice: 0,
                attributes: attrs,
                inventory: {
                    warehouseCode: 'WH-001',
                    physicalQuantity: 0,
                    minStockLevel: 10,
                    reorderPoint: 20,
                },
                barcodes: [],
            };
        });

        set({ variants });
    },

    addImages: (files) =>
        set((state) => {
            const newImages: ProductImage[] = files.map((file) => ({
                id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
                file,
                preview: URL.createObjectURL(file),
                isPrimary: state.images.length === 0,
            }));
            // İlk eklenen görseli primary yap (eğer henüz hiç yoksa)
            if (state.images.length === 0 && newImages.length > 0) {
                newImages[0].isPrimary = true;
            }
            return { images: [...state.images, ...newImages] };
        }),

    removeImage: (id) =>
        set((state) => {
            const filtered = state.images.filter((img) => img.id !== id);
            // Silinen primary ise ilk kalan görseli primary yap
            const wasPrimary = state.images.find((img) => img.id === id)?.isPrimary;
            if (wasPrimary && filtered.length > 0) {
                filtered[0].isPrimary = true;
            }
            return { images: filtered };
        }),

    setPrimaryImage: (id) =>
        set((state) => ({
            images: state.images.map((img) => ({
                ...img,
                isPrimary: img.id === id,
            })),
        })),

    reset: () =>
        set({
            productName: '',
            slug: '',
            categoryId: '',
            brand: '',
            basePrice: 0,
            description: '',
            variants: [],
            images: [],
        }),
}));