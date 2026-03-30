// src/features/pos/store/productWizardStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface AttributeType {
    id: string;
    name: string;
    values: string[];
}

export interface VariantItem {
    id?: string;
    sku: string;
    name: string;
    attributes: Record<string, string>;
    additionalPrice: number;
    imageUrl?: string;
    sortOrder: number;
    barcodes: BarcodeItem[];
    inventory?: InventoryItem;
}

export interface BarcodeItem {
    barcodeCode: string;
    barcodeType: 'EAN13' | 'UPC' | 'QR_CODE';
    isPrimary: boolean;
}

export interface InventoryItem {
    warehouseCode: string;
    physicalQuantity: number;
    minStockLevel: number;
    reorderPoint: number;
}

export interface ProductWizardState {
    currentStep: number;
    formData: {
        basicInfo: {
            name: string;
            slug?: string;
            shortDescription?: string;
            description?: string;
            categoryId: string;
            brand?: string;
            modelCode?: string;
            basePrice: number;
            costPrice?: number;
            taxRate: number;
            currency: string;
            status: 'DRAFT' | 'ACTIVE' | 'INACTIVE';
            featuredImage?: string;
            weight?: number;
            length?: number;
            width?: number;
            height?: number;
            metaTitle?: string;
            metaDescription?: string;
            metaKeywords?: string;
        };
        variants: {
            hasVariants: boolean;
            attributeTypes: AttributeType[];
            variantList: VariantItem[];
        };
        inventory: {
            warehouses: any[];
        };
        media: {
            images: any[];
            videos: any[];
        };
        pricing: {
            prices: any[];
            sites: string[];
        };
    };
}

interface ProductWizardStore extends ProductWizardState {
    setCurrentStep: (step: number) => void;
    nextStep: () => void;
    prevStep: () => void;
    setBasicInfo: (data: Partial<ProductWizardState['formData']['basicInfo']>) => void;
    setHasVariants: (hasVariants: boolean) => void;
    addAttributeType: (type: AttributeType) => void;
    removeAttributeType: (id: string) => void;
    updateAttributeType: (id: string, data: Partial<AttributeType>) => void;
    generateVariants: () => void;
    updateVariant: (index: number, data: Partial<VariantItem>) => void;
    removeVariant: (index: number) => void;
    setWarehouseInventory: (data: ProductWizardState['formData']['inventory']) => void;
    addMedia: (media: any) => void;
    removeMedia: (index: number) => void;
    setPrimaryMedia: (index: number) => void;
    setPricing: (data: ProductWizardState['formData']['pricing']) => void;
    resetForm: () => void;
    validateStep: (step: number) => boolean;
}

const initialState: ProductWizardState = {
    currentStep: 1,
    formData: {
        basicInfo: {
            name: '',
            categoryId: '',
            basePrice: 0,
            taxRate: 18,
            currency: 'TRY',
            status: 'ACTIVE',
        },
        variants: {
            hasVariants: false,
            attributeTypes: [],
            variantList: [],
        },
        inventory: {
            warehouses: [],
        },
        media: {
            images: [],
            videos: [],
        },
        pricing: {
            prices: [],
            sites: [],
        },
    },
};

export const useProductWizardStore = create<ProductWizardStore>()(
    persist(
        (set, get) => ({
            ...initialState,

            setCurrentStep: (step) => set({ currentStep: step }),

            nextStep: () => {
                const { currentStep } = get();
                if (currentStep < 5) {
                    set({ currentStep: currentStep + 1 });
                }
            },

            prevStep: () => {
                const { currentStep } = get();
                if (currentStep > 1) {
                    set({ currentStep: currentStep - 1 });
                }
            },

            setBasicInfo: (data) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        basicInfo: { ...state.formData.basicInfo, ...data },
                    },
                })),

            setHasVariants: (hasVariants) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            hasVariants,
                            variantList: hasVariants ? state.formData.variants.variantList : [],
                        },
                    },
                })),

            addAttributeType: (type) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            attributeTypes: [...state.formData.variants.attributeTypes, type],
                        },
                    },
                })),

            removeAttributeType: (id) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            attributeTypes: state.formData.variants.attributeTypes.filter(
                                (t) => t.id !== id
                            ),
                        },
                    },
                })),

            updateAttributeType: (id, data) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            attributeTypes: state.formData.variants.attributeTypes.map((t) =>
                                t.id === id ? { ...t, ...data } : t
                            ),
                        },
                    },
                })),

            generateVariants: () => {
                const { formData } = get();
                const { attributeTypes } = formData.variants;

                if (attributeTypes.length === 0) {
                    set((state) => ({
                        formData: {
                            ...state.formData,
                            variants: { ...state.formData.variants, variantList: [] },
                        },
                    }));
                    return;
                }

                const combinations = attributeTypes.reduce<Record<string, string>[]>(
                    (acc, attr) => {
                        if (acc.length === 0) {
                            return attr.values.map((value) => ({ [attr.name]: value }));
                        }

                        const newAcc: Record<string, string>[] = [];
                        acc.forEach((combo) => {
                            attr.values.forEach((value) => {
                                newAcc.push({ ...combo, [attr.name]: value });
                            });
                        });
                        return newAcc;
                    },
                    []
                );

                const variants: VariantItem[] = combinations.map((combo, index) => {
                    const name = Object.values(combo).join(' - ');
                    const sku = `${formData.basicInfo.name
                        .substring(0, 3)
                        .toUpperCase()}-${Object.values(combo)
                        .map((v) => v.substring(0, 3).toUpperCase())
                        .join('-')}`;

                    return {
                        sku,
                        name,
                        attributes: combo,
                        additionalPrice: 0,
                        sortOrder: index,
                        barcodes: [],
                    };
                });

                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: { ...state.formData.variants, variantList: variants },
                    },
                }));
            },

            updateVariant: (index, data) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            variantList: state.formData.variants.variantList.map((v, i) =>
                                i === index ? { ...v, ...data } : v
                            ),
                        },
                    },
                })),

            removeVariant: (index) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        variants: {
                            ...state.formData.variants,
                            variantList: state.formData.variants.variantList.filter(
                                (_, i) => i !== index
                            ),
                        },
                    },
                })),

            setWarehouseInventory: (data) =>
                set((state) => ({
                    formData: { ...state.formData, inventory: data },
                })),

            addMedia: (media) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        media: {
                            ...state.formData.media,
                            images: [...state.formData.media.images, media],
                        },
                    },
                })),

            removeMedia: (index) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        media: {
                            ...state.formData.media,
                            images: state.formData.media.images.filter((_, i) => i !== index),
                        },
                    },
                })),

            setPrimaryMedia: (index) =>
                set((state) => ({
                    formData: {
                        ...state.formData,
                        media: {
                            ...state.formData.media,
                            images: state.formData.media.images.map((img, i) => ({
                                ...img,
                                isPrimary: i === index,
                            })),
                        },
                    },
                })),

            setPricing: (data) =>
                set((state) => ({
                    formData: { ...state.formData, pricing: data },
                })),

            resetForm: () => set(initialState),

            validateStep: (step) => {
                const { formData } = get();

                switch (step) {
                    case 1:
                        return (
                            formData.basicInfo.name.trim() !== '' &&
                            formData.basicInfo.categoryId !== '' &&
                            formData.basicInfo.basePrice > 0
                        );

                    case 2:
                        if (!formData.variants.hasVariants) return true;
                        return formData.variants.variantList.length > 0;

                    case 3:
                        return true; // Stok opsiyonel

                    case 4:
                        return true; // Görsel opsiyonel

                    case 5:
                        return true; // Önizleme her zaman geçerli

                    default:
                        return true;
                }
            },
        }),
        {
            name: 'product-wizard-storage',
        }
    )
);