// src/features/pos/store/cartStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type {CartItem, OrderSummary, Product} from "../types/pos.types.ts";

interface CartState {
    items: CartItem[];
    customer: any | null;
    orderSummary: OrderSummary;

    addItem: (product: Product) => void;
    removeItem: (productId: number) => void;
    updateQuantity: (productId: number, quantity: number) => void;
    clearCart: () => void;
    setCustomer: (customer: any) => void;
    calculateSummary: () => void;
}

export const useCartStore = create<CartState>()(
    persist(
        (set, get) => ({
            items: [],
            customer: null,
            orderSummary: {
                subtotal: 0,
                shipping: 0,
                tax: 0,
                discount: 0,
                grandTotal: 0,
            },

            addItem: (product) => {
                const { items } = get();
                const existingItem = items.find((item) => item.product.id === product.id);

                if (existingItem) {
                    set({
                        items: items.map((item) =>
                            item.product.id === product.id
                                ? { ...item, quantity: item.quantity + 1, subtotal: (item.quantity + 1) * product.price }
                                : item
                        ),
                    });
                } else {
                    set({
                        items: [
                            ...items,
                            {
                                product,
                                quantity: 1,
                                subtotal: product.price,
                            },
                        ],
                    });
                }

                get().calculateSummary();
            },

            removeItem: (productId) => {
                set({
                    items: get().items.filter((item) => item.product.id !== productId),
                });
                get().calculateSummary();
            },

            updateQuantity: (productId, quantity) => {
                if (quantity <= 0) {
                    get().removeItem(productId);
                    return;
                }

                set({
                    items: get().items.map((item) =>
                        item.product.id === productId
                            ? { ...item, quantity, subtotal: quantity * item.product.price }
                            : item
                    ),
                });

                get().calculateSummary();
            },

            clearCart: () => {
                set({
                    items: [],
                    customer: null,
                    orderSummary: {
                        subtotal: 0,
                        shipping: 0,
                        tax: 0,
                        discount: 0,
                        grandTotal: 0,
                    },
                });
            },

            setCustomer: (customer) => {
                set({ customer });
            },

            calculateSummary: () => {
                const { items } = get();
                const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
                const shipping = 35;
                const taxRate = 0.15;
                const tax = subtotal * taxRate;
                const discountRate = 0.05;
                const discount = subtotal * discountRate;
                const grandTotal = subtotal + shipping + tax - discount;

                set({
                    orderSummary: {
                        subtotal,
                        shipping,
                        tax,
                        discount,
                        grandTotal,
                    },
                });
            },
        }),
        {
            name: 'pos-cart-storage',
        }
    )
);