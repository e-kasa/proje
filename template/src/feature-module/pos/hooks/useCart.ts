// src/features/pos/hooks/useCart.ts
import { useCartStore } from '../store/cartStore';

export const useCart = () => {
    const {
        items,
        customer,
        orderSummary,
        addItem,
        removeItem,
        updateQuantity,
        clearCart,
        setCustomer,
    } = useCartStore();

    return {
        items,
        customer,
        orderSummary,
        itemCount: items.length,
        totalQuantity: items.reduce((sum, item) => sum + item.quantity, 0),
        addItem,
        removeItem,
        updateQuantity,
        clearCart,
        setCustomer,
    };
};