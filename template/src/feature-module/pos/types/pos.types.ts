// src/features/pos/types/pos.types.ts

export interface Product {
    id: number;
    sku: string;
    name: string;
    categoryId: number;
    categoryName: string;
    brandId?: number;
    brandName?: string;
    price: number;
    cost?: number; // Maliyet fiyatı
    stock: number;
    minStock?: number; // Minimum stok seviyesi
    maxStock?: number; // Maksimum stok seviyesi
    imageUrl: string;
    images?: string[]; // Çoklu resim desteği
    barcode?: string;
    description?: string;
    unit?: string; // Adet, kg, lt vb.
    taxRate?: number; // KDV oranı
    isActive?: boolean;
    isFeatured?: boolean; // Öne çıkan ürün
    createdAt?: string;
    updatedAt?: string;
    variants?: ProductVariant[]; // Varyantlar (renk, beden vb.)
}

export interface ProductVariant {
    id: number;
    productId: number;
    sku: string;
    name: string; // Örn: "Kırmızı - L"
    attributes: VariantAttribute[]; // { name: "Renk", value: "Kırmızı" }
    price: number;
    stock: number;
    barcode?: string;
    imageUrl?: string;
}

export interface VariantAttribute {
    name: string; // Renk, Beden, Boyut vb.
    value: string; // Kırmızı, XL, 42 vb.
}

export interface CartItem {
    product: Product;
    variant?: ProductVariant; // Seçili varyant
    quantity: number;
    subtotal: number;
    discount?: number; // Ürün bazlı indirim
    tax?: number; // Ürün bazlı vergi
    batchNo?: string;
    note?: string; // Ürün notu
}

export interface Category {
    id: number;
    name: string;
    imageUrl: string;
    itemCount: number;
    parentId?: number; // Alt kategori desteği
    description?: string;
    isActive?: boolean;
    sortOrder?: number;
}

export interface Brand {
    id: number;
    name: string;
    logoUrl?: string;
    description?: string;
    isActive?: boolean;
}

export interface OrderSummary {
    subtotal: number;
    shipping: number;
    tax: number;
    discount: number;
    couponDiscount?: number; // Kupon indirimi
    loyaltyDiscount?: number; // Sadakat indirimi
    roundingAmount?: number; // Yuvarlama tutarı
    grandTotal: number;
}

export interface Customer {
    id: number | string;
    name: string;
    phone?: string;
    email?: string;
    address?: string;
    city?: string;
    district?: string;
    zipCode?: string;
    taxNumber?: string; // Vergi numarası
    taxOffice?: string; // Vergi dairesi
    loyaltyPoints?: number;
    bonus?: number;
    totalSpent?: number; // Toplam harcama
    orderCount?: number; // Sipariş sayısı
    lastOrderDate?: string;
    createdAt?: string;
    isActive?: boolean;
    customerType?: 'individual' | 'corporate'; // Bireysel / Kurumsal
    notes?: string;
}

export interface PaymentMethod {
    id: string;
    name: string;
    icon: string;
    type: 'cash' | 'card' | 'points' | 'deposit' | 'cheque' | 'scan' | 'split' | 'later' | 'gift';
    isActive?: boolean;
    fee?: number; // İşlem ücreti
    feeType?: 'fixed' | 'percentage'; // Sabit / Yüzde
}

export interface Payment {
    id: string;
    method: PaymentMethod;
    amount: number;
    timestamp: string;
    reference?: string; // Referans numarası
    cardLastFour?: string; // Kart son 4 hane
    installment?: number; // Taksit sayısı
}

export interface Order {
    id: string;
    orderNumber: string;
    customer?: Customer;
    items: CartItem[];
    summary: OrderSummary;
    payments: Payment[];
    status: OrderStatus;
    type: OrderType;
    createdAt: string;
    updatedAt?: string;
    completedAt?: string;
    notes?: string;
    cashier?: string; // Kasa görevlisi
    cashierName?: string;
}

export type OrderStatus =
    | 'draft' // Taslak
    | 'pending' // Beklemede
    | 'hold' // Beklet
    | 'processing' // İşleniyor
    | 'completed' // Tamamlandı
    | 'cancelled' // İptal
    | 'refunded'; // İade

export type OrderType =
    | 'pos' // POS satışı
    | 'online' // Online sipariş
    | 'phone' // Telefonla sipariş
    | 'return'; // İade

export interface Warehouse {
    id: number;
    name: string;
    code: string;
    address?: string;
    isActive?: boolean;
    isDefault?: boolean;
}

export interface StockMovement {
    id: number;
    productId: number;
    variantId?: number;
    warehouseId: number;
    quantity: number;
    type: StockMovementType;
    reason?: string;
    reference?: string; // Sipariş/Fatura no
    createdBy?: string;
    createdAt: string;
}

export type StockMovementType =
    | 'purchase' // Satın alma
    | 'sale' // Satış
    | 'return' // İade
    | 'adjustment' // Düzeltme
    | 'transfer'; // Transfer

export interface Discount {
    id: string;
    code?: string; // Kupon kodu
    name: string;
    type: 'fixed' | 'percentage';
    value: number;
    minAmount?: number; // Minimum tutar
    maxDiscount?: number; // Maksimum indirim
    startDate?: string;
    endDate?: string;
    isActive?: boolean;
    usageLimit?: number; // Kullanım limiti
    usageCount?: number; // Kullanım sayısı
}

export interface Tax {
    id: number;
    name: string;
    rate: number; // Oran (%)
    isActive?: boolean;
}

export interface Shift {
    id: string;
    cashier: string;
    cashierName: string;
    startTime: string;
    endTime?: string;
    startingCash: number;
    endingCash?: number;
    expectedCash?: number;
    difference?: number;
    totalSales?: number;
    totalOrders?: number;
    status: 'open' | 'closed';
    notes?: string;
}

export interface PosSettings {
    taxEnabled: boolean;
    taxRate: number;
    shippingEnabled: boolean;
    shippingCost: number;
    discountEnabled: boolean;
    defaultDiscount: number;
    roundingEnabled: boolean;
    autoHoldOrders: boolean;
    printReceipt: boolean;
    defaultWarehouseId?: number;
    receiptTemplate?: string;
}

// Arama ve Filtreleme
export interface ProductFilters {
    categoryId?: number;
    brandId?: number;
    searchQuery?: string;
    minPrice?: number;
    maxPrice?: number;
    inStock?: boolean;
    isFeatured?: boolean;
    sortBy?: 'name' | 'price' | 'stock' | 'createdAt';
    sortOrder?: 'asc' | 'desc';
}

export interface OrderFilters {
    status?: OrderStatus;
    type?: OrderType;
    customerId?: number;
    startDate?: string;
    endDate?: string;
    minAmount?: number;
    maxAmount?: number;
    cashier?: string;
}

// API Response Types
export interface ApiResponse<T> {
    success: boolean;
    data?: T;
    message?: string;
    errors?: Record<string, string[]>;
}

export interface PaginatedResponse<T> {
    data: T[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
}

// Form Types
export interface ProductFormData {
    name: string;
    sku: string;
    categoryId: number;
    brandId?: number;
    price: number;
    cost?: number;
    stock: number;
    barcode?: string;
    description?: string;
    unit?: string;
    taxRate?: number;
    imageUrl?: string;
}

export interface CustomerFormData {
    name: string;
    phone?: string;
    email?: string;
    address?: string;
    city?: string;
    district?: string;
    taxNumber?: string;
    taxOffice?: string;
    customerType?: 'individual' | 'corporate';
}

// Hook Return Types
export interface UseCartReturn {
    items: CartItem[];
    customer?: Customer;
    orderSummary: OrderSummary;
    itemCount: number;
    totalQuantity: number;
    addItem: (product: Product, variant?: ProductVariant) => void;
    removeItem: (productId: number, variantId?: number) => void;
    updateQuantity: (productId: number, quantity: number, variantId?: number) => void;
    clearCart: () => void;
    setCustomer: (customer: Customer | undefined) => void;
    applyDiscount: (discount: Discount) => void;
    removeDiscount: () => void;
}

export interface UseProductsReturn {
    products: Product[];
    loading: boolean;
    error: string | null;
    refetch: () => void;
}

export interface UseCategoriesReturn {
    categories: Category[];
    loading: boolean;
    error: string | null;
}

export interface UseOrdersReturn {
    orders: Order[];
    loading: boolean;
    error: string | null;
    createOrder: (order: Partial<Order>) => Promise<void>;
    updateOrder: (id: string, updates: Partial<Order>) => Promise<void>;
    cancelOrder: (id: string) => Promise<void>;
    refetch: () => void;
}