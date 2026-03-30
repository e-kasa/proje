// src/features/pos/components/OrderPanel/OrderList.tsx
import { Link } from 'react-router-dom';
import {useCart} from "../../feature-module/pos/hooks/useCart.ts";
import {useAlert} from "../AlertContext.tsx";

export const OrderList = () => {
    const { items, removeItem, updateQuantity } = useCart();
    const { showAlert } = useAlert();

    const handleQuantityChange = (
        productId: number,
        currentQuantity: number,
        newQuantity: number,
        maxStock: number
    ) => {
        if (newQuantity > maxStock) {
            showAlert({
                type: 'warning',
                message: `Stok yetersiz! Maksimum ${maxStock} adet seçebilirsiniz.`,
                autoClose: 3000,
            });
            return;
        }

        updateQuantity(productId, newQuantity);
    };

    if (items.length === 0) {
        return (
            <div className="empty-cart">
                <div className="fs-24 mb-1">
                    <i className="ti ti-shopping-cart" />
                </div>
                <p className="fw-bold">Ürün Seçilmedi</p>
            </div>
        );
    }

    return (
        <div className="product-list border-0 p-0" style={{ display: 'block' }}>
            <div className="table-responsive">
                <table className="table table-borderless">
                    <thead>
                    <tr>
                        <th className="fw-bold bg-light">Ürün</th>
                        <th className="fw-bold bg-light">Adet</th>
                        <th className="fw-bold bg-light text-end">Fiyat</th>
                    </tr>
                    </thead>
                    <tbody>
                    {items.map((item) => (
                        <tr key={item.product.id}>
                            <td>
                                <div className="d-flex align-items-center">
                                    <Link
                                        className="delete-icon"
                                        to="#"
                                        onClick={() => removeItem(item.product.id)}
                                    >
                                        <i className="ti ti-trash-x-filled" />
                                    </Link>
                                    <h6 className="fs-13 fw-normal">
                                        <Link to="#" className="link-default">
                                            {item.product.name}
                                        </Link>
                                    </h6>
                                </div>
                            </td>
                            <td>
                                <div className="qty-item m-0 d-flex align-items-center">
                                    <button
                                        className="btn btn-sm btn-light"
                                        onClick={() =>
                                            handleQuantityChange(
                                                item.product.id,
                                                item.quantity,
                                                item.quantity - 1,
                                                item.product.stock
                                            )
                                        }
                                        disabled={item.quantity <= 1}
                                    >
                                        <i className="ti ti-minus" />
                                    </button>
                                    <input
                                        type="text"
                                        className="form-control text-center mx-1"
                                        value={item.quantity}
                                        readOnly
                                        style={{ width: '50px' }}
                                    />
                                    <button
                                        className="btn btn-sm btn-light"
                                        onClick={() =>
                                            handleQuantityChange(
                                                item.product.id,
                                                item.quantity,
                                                item.quantity + 1,
                                                item.product.stock
                                            )
                                        }
                                        disabled={item.quantity >= item.product.stock}
                                    >
                                        <i className="ti ti-plus" />
                                    </button>
                                </div>
                            </td>
                            <td className="fs-13 fw-semibold text-gray-9 text-end">
                                ₺{item.subtotal.toLocaleString('tr-TR')}
                            </td>
                        </tr>
                    ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};