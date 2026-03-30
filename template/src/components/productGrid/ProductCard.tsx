// src/features/pos/components/ProductGrid/ProductCard.tsx
import { Link } from 'react-router-dom';
import type {Product} from "../../feature-module/pos/types/pos.types.ts";
import {useCart} from "../../feature-module/pos/hooks/useCart.ts";
import {useAlert} from "../AlertContext.tsx";

interface ProductCardProps {
    product: Product;
    isActive?: boolean;
}

export const ProductCard = ({ product, isActive = false }: ProductCardProps) => {
    const { addItem, items } = useCart();
    const { showAlert } = useAlert();

    const handleClick = () => {
        const cartItem = items.find((item) => item.product.id === product.id);
        const currentQuantity = cartItem?.quantity || 0;

        if (product.stock === 0) {
            showAlert({
                type: 'danger',
                message: `${product.name} stokta yok!`,
                autoClose: 3000,
            });
            return;
        }

        if (currentQuantity >= product.stock) {
            showAlert({
                type: 'warning',
                message: `${product.name} için maksimum stok adedine ulaştınız (${product.stock} adet)`,
                autoClose: 3000,
            });
            return;
        }

        addItem(product);
    };

    const isOutOfStock = product.stock === 0;
    const cartItem = items.find((item) => item.product.id === product.id);

    return (
        <div
            className={`product-info card mb-0 ${isActive ? 'active' : ''}`}
            onClick={handleClick}
            tabIndex={0}
            role="button"
        >
            <Link to="#" className="pro-img" onClick={(e) => e.preventDefault()}>
                <img src={product.imageUrl} alt={product.name} />
                <span>
          <i className="ti ti-circle-check-filled" />
        </span>
                {isOutOfStock && (
                    <div className="position-absolute top-50 start-50 translate-middle">
                        <span className="badge bg-danger">STOKTA YOK</span>
                    </div>
                )}
            </Link>
            <h6 className="cat-name">
                <Link to="#" onClick={(e) => e.preventDefault()}>
                    {product.categoryName}
                </Link>
            </h6>
            <h6 className="product-name">
                <Link to="#" onClick={(e) => e.preventDefault()}>
                    {product.name}
                </Link>
            </h6>
            <div className="d-flex align-items-center justify-content-between price">
                <p className="text-gray-9 mb-0">
                    ₺{product.price.toLocaleString('tr-TR')}
                </p>
                <div className="qty-item m-0">
                    {cartItem ? (
                        <span className="badge bg-info">{cartItem.quantity} adet</span>
                    ) : (
                        <span className="text-muted small">
              <i className="ti ti-package me-1" />
                            {product.stock}
            </span>
                    )}
                </div>
            </div>
        </div>
    );
};