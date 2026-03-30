// src/features/pos/components/OrderPanel/PaymentMethods.tsx
import { Link } from 'react-router-dom';

export const PaymentMethods = () => {
    return (
        <>
            <h5 className="mb-3">Ödeme Yöntemi Seç</h5>
            <div className="row align-items-center methods g-2">
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#payment-cash"
                    >
                        <span className="fs-3 me-2">💵</span>
                        <p className="fs-14 fw-medium mb-0">Nakit</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#payment-card"
                    >
                        <span className="fs-3 me-2">💳</span>
                        <p className="fs-14 fw-medium mb-0">Kart</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#payment-points"
                    >
                        <span className="fs-3 me-2">⭐</span>
                        <p className="fs-14 fw-medium mb-0">Puan</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#payment-deposit"
                    >
                        <span className="fs-3 me-2">🏦</span>
                        <p className="fs-14 fw-medium mb-0">Havale</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#payment-cheque"
                    >
                        <span className="fs-3 me-2">📝</span>
                        <p className="fs-14 fw-medium mb-0">Çek</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#gift-payment"
                    >
                        <span className="fs-3 me-2">🎁</span>
                        <p className="fs-14 fw-medium mb-0">Hediye</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#scan-payment"
                    >
                        <span className="fs-3 me-2">📱</span>
                        <p className="fs-14 fw-medium mb-0">QR</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                    >
                        <span className="fs-3 me-2">⏰</span>
                        <p className="fs-14 fw-medium mb-0">Sonra Öde</p>
                    </Link>
                </div>
                <div className="col-sm-6 col-md-4 d-flex">
                    <Link
                        to="#"
                        className="payment-item d-flex align-items-center justify-content-center p-2 flex-fill"
                        data-bs-toggle="modal"
                        data-bs-target="#split-payment"
                    >
                        <span className="fs-3 me-2">✂️</span>
                        <p className="fs-14 fw-medium mb-0">Böl</p>
                    </Link>
                </div>
            </div>
        </>
    );
};