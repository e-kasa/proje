// src/features/pos/components/ProductGrid/ProductGrid.tsx
import { ProductCard } from './ProductCard';
import {useProducts} from "../../feature-module/pos/hooks/useProducts.ts";
import {useCart} from "../../feature-module/pos/hooks/useCart.ts";

interface ProductGridProps {
    categoryId?: number;
    searchQuery?: string;
}

export const ProductGrid = ({ categoryId, searchQuery }: ProductGridProps) => {
    const { products, loading } = useProducts(categoryId);
    const { items } = useCart();

    const filteredProducts = products.filter((product) =>
        product.name.toLowerCase().includes(searchQuery?.toLowerCase() || '')
    );

    if (loading) {
        return (
            <div className="text-center py-5">
                <div className="spinner-border text-primary" role="status">
                    <span className="visually-hidden">Yükleniyor...</span>
                </div>
                <p className="mt-3 text-muted">Ürünler yükleniyor...</p>
            </div>
        );
    }

    return (
        <div className="tabs_container">
            <div className="tab_content active" data-tab="all">
                <div className="row g-3">
                    {filteredProducts.map((product) => {
                        const isInCart = items.some((item) => item.product.id === product.id);

                        return (
                            <div
                                key={product.id}
                                className="col-sm-6 col-md-6 col-lg-6 col-xl-4 col-xxl-3"
                            >
                                <ProductCard product={product} isActive={isInCart} />
                            </div>
                        );
                    })}

                    {filteredProducts.length === 0 && (
                        <div className="col-12 text-center py-5">
                            <i className="ti ti-package-off fs-1 text-muted d-block mb-3" />
                            <p className="text-muted">Ürün bulunamadı</p>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};