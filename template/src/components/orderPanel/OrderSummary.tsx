// src/features/pos/components/OrderPanel/OrderSummary.tsx
import { Link } from 'react-router-dom';
import {useCart} from "../../feature-module/pos/hooks/useCart.ts";

export const OrderSummary = () => {
    const { orderSummary } = useCart();

    return (
        <table className="table table-responsive table-borderless">
            <tbody>
            <tr>
                <td>
                    Kargo
                    <Link
                        to="#"
                        className="ms-3 link-default"
                        data-bs-toggle="modal"
                        data-bs-target="#shipping-cost"
                    >
                        <i className="ti ti-edit" />
                    </Link>
                </td>
                <td className="text-gray-9 text-end">
                    ₺{orderSummary.shipping.toLocaleString('tr-TR')}
                </td>
            </tr>
            <tr>
                <td>
                    Vergi
                    <Link
                        to="#"
                        className="ms-3 link-default"
                        data-bs-toggle="modal"
                        data-bs-target="#order-tax"
                    >
                        <i className="ti ti-edit" />
                    </Link>
                </td>
                <td className="text-gray-9 text-end">
                    ₺{orderSummary.tax.toLocaleString('tr-TR')}
                </td>
            </tr>
            <tr>
                <td>
                    Kupon
                    <Link
                        to="#"
                        className="ms-3 link-default"
                        data-bs-toggle="modal"
                        data-bs-target="#coupon-code"
                    >
                        <i className="ti ti-edit" />
                    </Link>
                </td>
                <td className="text-gray-9 text-end">₺25</td>
            </tr>
            <tr>
                <td>
                    <span className="text-danger">İndirim</span>
                    <Link
                        to="#"
                        className="ms-3 link-default"
                        data-bs-toggle="modal"
                        data-bs-target="#discount"
                    >
                        <i className="ti ti-edit" />
                    </Link>
                </td>
                <td className="text-danger text-end">
                    -₺{orderSummary.discount.toLocaleString('tr-TR')}
                </td>
            </tr>
            <tr>
                <td>
                    <div className="form-check form-switch">
                        <input
                            className="form-check-input"
                            type="checkbox"
                            role="switch"
                            id="round"
                            defaultChecked
                        />
                        <label className="form-check-label" htmlFor="round">
                            Yuvarlama
                        </label>
                    </div>
                </td>
                <td className="text-gray-9 text-end">+₺0.11</td>
            </tr>
            <tr>
                <td>Ara Toplam</td>
                <td className="text-gray-9 text-end">
                    ₺{orderSummary.subtotal.toLocaleString('tr-TR')}
                </td>
            </tr>
            <tr>
                <td className="fw-bold border-top border-dashed">Toplam</td>
                <td className="text-gray-9 fw-bold text-end border-top border-dashed">
                    ₺{orderSummary.grandTotal.toLocaleString('tr-TR')}
                </td>
            </tr>
            </tbody>
        </table>
    );
};