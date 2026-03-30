// src/features/pos/hooks/useCategories.ts
import { useState, useEffect } from 'react';
import type {Category} from "../types/pos.types.ts";

export const useCategories = () => {
    const [categories, setCategories] = useState<Category[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Mock data - Gerçek API'den veri çekilecek
        const mockCategories: Category[] = [
            {
                id: 1,
                name: 'Telefon',
                imageUrl: 'https://via.placeholder.com/60x60/f093fb/ffffff?text=📱',
                itemCount: 45,
            },
            {
                id: 2,
                name: 'Bilgisayar',
                imageUrl: 'https://via.placeholder.com/60x60/4facfe/ffffff?text=💻',
                itemCount: 23,
            },
            {
                id: 3,
                name: 'Aksesuar',
                imageUrl: 'https://via.placeholder.com/60x60/43e97b/ffffff?text=🎧',
                itemCount: 78,
            },
            {
                id: 4,
                name: 'Saat',
                imageUrl: 'https://via.placeholder.com/60x60/fa709a/ffffff?text=⌚',
                itemCount: 34,
            },
            {
                id: 5,
                name: 'Tablet',
                imageUrl: 'https://via.placeholder.com/60x60/fee140/ffffff?text=📲',
                itemCount: 19,
            },
            {
                id: 6,
                name: 'TV & Ses',
                imageUrl: 'https://via.placeholder.com/60x60/30cfd0/ffffff?text=📺',
                itemCount: 12,
            },
            {
                id: 7,
                name: 'Kamera',
                imageUrl: 'https://via.placeholder.com/60x60/a8edea/ffffff?text=📷',
                itemCount: 28,
            },
            {
                id: 8,
                name: 'Oyun',
                imageUrl: 'https://via.placeholder.com/60x60/fed6e3/ffffff?text=🎮',
                itemCount: 56,
            },
        ];

        setTimeout(() => {
            setCategories(mockCategories);
            setLoading(false);
        }, 200);
    }, []);

    return { categories, loading };
};
