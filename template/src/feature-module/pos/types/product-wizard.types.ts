// src/features/pos/types/product-wizard.types.ts
export interface ProductWizardState {
    // Step 1: Temel Bilgiler
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

    // Step 2: Varyantlar
    variants: {
        hasVariants: boolean;
        attributeTypes: AttributeType[]; // Renk, Beden, vb.
        variantList: VariantItem[];
    };

    // Step 3: Stok & Barkod
    inventory: {
        warehouses: WarehouseInventory[];
    };

    // Step 4: Görseller
    media: {
        images: MediaItem[];
        videos: MediaItem[];
    };

    // Step 5: Fiyatlandırma & Site
    pricing: {
        prices: PriceItem[];
        sites: string[];
    };
}

export interface AttributeType {
    id: string;
    name: string; // "Renk", "Beden", "Depolama"
    values: string[]; // ["Siyah", "Beyaz", "Kırmızı"]
}

export interface VariantItem {
    id?: string;
    sku: string;
    name: string;
    attributes: Record<string, string>; // { color: "Siyah", size: "XL" }
    additionalPrice: number;
    imageUrl?: string;
    sortOrder: number;
    barcodes: BarcodeItem[];
}

export interface BarcodeItem {
    code: string;
    type: 'EAN13' | 'UPC' | 'QR_CODE';
    isPrimary: boolean;
}

export interface WarehouseInventory {
    warehouseCode: string;
    warehouseName: string;
    variantInventories: {
        variantId?: string;
        variantSku: string;
        variantName: string;
        quantity: number;
        minStockLevel: number;
        maxStockLevel?: number;
        reorderPoint?: number;
        location?: string;
    }[];
}

export interface MediaItem {
    id?: string;
    url: string;
    thumbnailUrl?: string;
    title?: string;
    altText?: string;
    isPrimary: boolean;
    sortOrder: number;
    variantId?: string;
    file?: File; // Upload için
}

export interface PriceItem {
    siteId: string;
    siteName: string;
    variantId?: string;
    variantSku?: string;
    price: number;
    listPrice?: number;
    discountPercentage?: number;
    startDate?: string;
    endDate?: string;
    minOrderQuantity: number;
    maxOrderQuantity?: number;
}