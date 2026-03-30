// src/features/pos/hooks/useProducts.ts
import { useState, useEffect } from 'react';
import type {Product} from "../types/pos.types.ts";

const MOCK_PRODUCTS: Product[] = [
    {
        id: 1,
        sku: 'PROD-001',
        name: 'iPhone 14 Pro',
        categoryId: 1,
        categoryName: 'Telefon',
        price: 35000,
        stock: 15,
        imageUrl: 'https://via.placeholder.com/200x200/667eea/ffffff?text=iPhone+14',
    },
    {
        id: 2,
        sku: 'PROD-002',
        name: 'MacBook Pro M3',
        categoryId: 2,
        categoryName: 'Bilgisayar',
        price: 75000,
        stock: 8,
        imageUrl: 'https://via.placeholder.com/200x200/764ba2/ffffff?text=MacBook',
    },
    {
        id: 3,
        sku: 'PROD-003',
        name: 'AirPods Pro 2',
        categoryId: 3,
        categoryName: 'Aksesuar',
        price: 8500,
        stock: 25,
        imageUrl: 'https://via.placeholder.com/200x200/f093fb/ffffff?text=AirPods',
    },
    {
        id: 4,
        sku: 'PROD-004',
        name: 'Apple Watch Ultra',
        categoryId: 4,
        categoryName: 'Saat',
        price: 28000,
        stock: 12,
        imageUrl: 'https://via.placeholder.com/200x200/4facfe/ffffff?text=Watch',
    },
    {
        id: 5,
        sku: 'PROD-005',
        name: 'iPad Air M2',
        categoryId: 5,
        categoryName: 'Tablet',
        price: 22000,
        stock: 18,
        imageUrl: 'https://via.placeholder.com/200x200/00f2fe/ffffff?text=iPad',
    },
    {
        id: 6,
        sku: 'PROD-006',
        name: 'Samsung S24 Ultra',
        categoryId: 1,
        categoryName: 'Telefon',
        price: 42000,
        stock: 10,
        imageUrl: 'https://via.placeholder.com/200x200/43e97b/ffffff?text=Samsung',
    },
    {
        id: 7,
        sku: 'PROD-007',
        name: 'Dell XPS 15',
        categoryId: 2,
        categoryName: 'Bilgisayar',
        price: 55000,
        stock: 6,
        imageUrl: 'https://via.placeholder.com/200x200/38f9d7/ffffff?text=Dell',
    },
    {
        id: 8,
        sku: 'PROD-008',
        name: 'Sony WH-1000XM5',
        categoryId: 3,
        categoryName: 'Aksesuar',
        price: 12000,
        stock: 20,
        imageUrl: 'https://via.placeholder.com/200x200/fa709a/ffffff?text=Sony',
    },
];

export const useProducts = (categoryId?: number) => {
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        setLoading(true);
        setTimeout(() => {
            if (categoryId) {
                setProducts(MOCK_PRODUCTS.filter((p) => p.categoryId === categoryId));
            } else {
                setProducts(MOCK_PRODUCTS);
            }
            setLoading(false);
        }, 300);
    }, [categoryId]);

    return { products, loading, refetch: () => {} };
};
