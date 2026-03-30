// src/features/pos/components/OrderPanel/OrderPanel.tsx
import { Link } from 'react-router-dom';
import { OrderList } from './OrderList';
import { OrderSummary } from './OrderSummary';
import { PaymentMethods } from './PaymentMethods';
import { useState } from 'react';
import {useCart} from "../../feature-module/pos/hooks/useCart.ts";
import CommonSelect from "../select/common-select.tsx";

export const OrderPanel = () => {
    const { items, orderSummary, clearCart, setCustomer } = useCart();
    const [selectedCustomer, setSelectedCustomer] = useState(null);

    const customerOptions = [
        { value: '1', label: 'Müşteri 1' },
        { value: '2', label: 'Müşteri 2' },
        { value: '3', label: 'Müşteri 3' },
        { value: '4', label: 'Müşteri 4' },
        { value: '5', label: 'Müşteri 5' },
    ];

    const handleCustomerChange = (option: any) => {
        setSelectedCustomer(option);
        setCustomer({ id: option.value, name: option.label });
    };

    return (
        <aside className="product-order-list bg-secondary-transparent flex-fill">
            <div className="card">
                <div className="card-body">

                    {/* Header */}
                    <div className="order-head d-flex align-items-center justify-content-between w-100">
                        <div>
                            <h3>Sipariş Listesi</h3>
                        </div>
                        <div className="d-flex align-items-center gap-2">
              <span className="badge badge-dark fs-10 fw-medium badge-xs">
                #ORD{Math.floor(Math.random() * 1000)}
              </span>
                            <button className="link-danger fs-16 btn btn-link p-0" onClick={clearCart}>
                                <i className="ti ti-trash-x-filled" />
                            </button>
                        </div>
                    </div>

                    {/* Müşteri Bilgileri */}
                    <div className="customer-info block-section">
                        <h5 className="mb-2">Müşteri Bilgileri</h5>
                        <div className="d-flex align-items-center gap-2">
                            <div className="flex-grow-1">
                                <CommonSelect
                                    options={customerOptions}
                                    classNamePrefix="react-select select"
                                    placeholder="Müşteri Seçin"
                                    value={selectedCustomer}
                                    onChange={handleCustomerChange}
                                />
                            </div>
                            <Link
                                to="#"
                                className="btn btn-teal btn-icon fs-20"
                                data-bs-toggle="modal"
                                data-bs-target="#create"
                            >
                                <i className="ti ti-user-plus" />
                            </Link>
                            <Link
                                to="#"
                                className="btn btn-info btn-icon fs-20"
                                data-bs-toggle="modal"
                                data-bs-target="#barcode"
                            >
                                <i className="ti ti-scan" />
                            </Link>
                        </div>
                    </div>

                    {/* Sipariş Detayları */}
                    <div className="product-added block-section">
                        <div className="head-text d-flex align-items-center justify-content-between mb-3">
                            <div className="d-flex align-items-center">
                                <h5 className="me-2">Sipariş Detayları</h5>
                                <div className="badge bg-light text-gray-9 fs-12 fw-semibold py-2 border rounded">
                                    Ürün : <span className="text-teal">{items.length}</span>
                                </div>
                            </div>
                            <Link
                                to="#"
                                className="d-flex align-items-center clear-icon fs-10 fw-medium"
                                onClick={clearCart}
                            >
                                Tümünü Temizle
                            </Link>
                        </div>
                        <div className="product-wrap">
                            <OrderList />
                        </div>
                    </div>

                    {/* Ödeme Özeti */}
                    <div className="order-total bg-total bg-white p-0">
                        <h5 className="mb-3">Ödeme Özeti</h5>
                        <OrderSummary />
                    </div>
                </div>
            </div>

            {/* Ödeme Yöntemleri */}
            <div className="card payment-method">
                <div className="card-body">
                    <PaymentMethods />
                </div>
            </div>

            {/* Alt Butonlar */}
            <div className="btn-row d-flex align-items-center justify-content-between gap-3">
                <Link
                    to="#"
                    className="btn btn-white d-flex align-items-center justify-content-center flex-fill m-0"
                    data-bs-toggle="modal"
                    data-bs-target="#hold-order"
                >
                    <i className="ti ti-printer me-2" />
                    Yazdır
                </Link>
                <Link
                    to="#"
                    className="btn btn-secondary d-flex align-items-center justify-content-center flex-fill m-0"
                >
                    <i className="ti ti-shopping-cart me-2" />
                    Sipariş Ver
                </Link>
            </div>
        </aside>
    );
};