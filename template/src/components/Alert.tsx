// src/components/Alert.tsx
import React, { useEffect, useState } from "react";

interface AlertProps {
    type?: "success" | "danger" | "warning" | "info";
    message: string;
    autoClose?: number;
    onClose: () => void;
}

const Alert: React.FC<AlertProps> = ({
                                         type = "info",
                                         message,
                                         autoClose = 3000,
                                         onClose,
                                     }) => {
    const [isVisible, setIsVisible] = useState(true);
    const [progress, setProgress] = useState(100);

    useEffect(() => {
        if (autoClose) {
            const interval = setInterval(() => {
                setProgress((prev) => Math.max(prev - (100 / (autoClose / 100)), 0));
            }, 100);

            const timer = setTimeout(() => {
                setIsVisible(false);
                setTimeout(onClose, 300);
            }, autoClose);

            return () => {
                clearInterval(interval);
                clearTimeout(timer);
            };
        }
    }, [autoClose, onClose]);

    const handleClose = () => {
        setIsVisible(false);
        setTimeout(onClose, 300);
    };

    const getAlertConfig = () => {
        switch (type) {
            case "success":
                return {
                    bgClass: "bg-success",
                    icon: "ti-circle-check",
                    title: "Başarılı!",
                    iconBg: "bg-success-transparent",
                };
            case "danger":
                return {
                    bgClass: "bg-danger",
                    icon: "ti-circle-x",
                    title: "Hata!",
                    iconBg: "bg-danger-transparent",
                };
            case "warning":
                return {
                    bgClass: "bg-warning",
                    icon: "ti-alert-triangle",
                    title: "Uyarı!",
                    iconBg: "bg-warning-transparent",
                };
            case "info":
                return {
                    bgClass: "bg-info",
                    icon: "ti-info-circle",
                    title: "Bilgi",
                    iconBg: "bg-info-transparent",
                };
            default:
                return {
                    bgClass: "bg-info",
                    icon: "ti-info-circle",
                    title: "Bilgi",
                    iconBg: "bg-info-transparent",
                };
        }
    };

    const config = getAlertConfig();

    if (!isVisible) return null;

    return (
        <>
            <div
                className={`toast-container position-fixed top-0 end-0 p-3`}
                style={{ zIndex: 9999 }}
            >
                <div
                    className={`toast show align-items-center border-0 shadow-lg ${
                        isVisible ? "toast-slide-in" : "toast-slide-out"
                    }`}
                    role="alert"
                    aria-live="assertive"
                    aria-atomic="true"
                    style={{
                        minWidth: "350px",
                        maxWidth: "500px",
                        background: "white",
                        borderLeft: `4px solid var(--bs-${type})`,
                    }}
                >
                    <div className="d-flex p-3">
                        {/* Icon */}
                        <div className={`toast-icon ${config.iconBg} me-3`}>
                            <i className={`ti ${config.icon} fs-4`}></i>
                        </div>

                        {/* Content */}
                        <div className="toast-body flex-grow-1 p-0">
                            <div className="d-flex align-items-center justify-content-between mb-1">
                                <h6 className="mb-0 fw-semibold text-dark">{config.title}</h6>
                                <button
                                    type="button"
                                    className="btn-close btn-close-sm"
                                    onClick={handleClose}
                                    aria-label="Close"
                                    style={{
                                        fontSize: "10px",
                                        opacity: 0.6,
                                    }}
                                ></button>
                            </div>
                            <p className="mb-0 text-muted fs-14">{message}</p>
                        </div>
                    </div>

                    {/* Progress Bar */}
                    {autoClose && (
                        <div
                            className="progress"
                            style={{
                                height: "3px",
                                borderRadius: "0 0 6px 6px",
                            }}
                        >
                            <div
                                className={`progress-bar ${config.bgClass}`}
                                role="progressbar"
                                style={{
                                    width: `${progress}%`,
                                    transition: "width 0.1s linear",
                                }}
                            ></div>
                        </div>
                    )}
                </div>
            </div>

            <style>{`
        /* Toast Animations */
        @keyframes toast-slide-in {
          from {
            transform: translateX(400px);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }

        @keyframes toast-slide-out {
          from {
            transform: translateX(0);
            opacity: 1;
          }
          to {
            transform: translateX(400px);
            opacity: 0;
          }
        }

        .toast-slide-in {
          animation: toast-slide-in 0.3s ease-out forwards;
        }

        .toast-slide-out {
          animation: toast-slide-out 0.3s ease-in forwards;
        }

        /* Toast Styles */
        .toast {
          border-radius: 8px;
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15) !important;
        }

        .toast-icon {
          width: 40px;
          height: 40px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        /* Transparent Backgrounds */
        .bg-success-transparent {
          background-color: rgba(40, 167, 69, 0.1);
          color: var(--bs-success);
        }

        .bg-danger-transparent {
          background-color: rgba(220, 53, 69, 0.1);
          color: var(--bs-danger);
        }

        .bg-warning-transparent {
          background-color: rgba(255, 193, 7, 0.1);
          color: var(--bs-warning);
        }

        .bg-info-transparent {
          background-color: rgba(13, 202, 240, 0.1);
          color: var(--bs-info);
        }

        /* Font Size */
        .fs-14 {
          font-size: 14px;
        }

        /* Button Close */
        .btn-close-sm {
          padding: 0;
          width: 16px;
          height: 16px;
          background-size: 10px;
        }

        /* Responsive */
        @media (max-width: 576px) {
          .toast-container {
            padding: 10px !important;
          }

          .toast {
            min-width: 280px !important;
            max-width: 100% !important;
          }

          .toast-icon {
            width: 35px;
            height: 35px;
          }

          .toast-body {
            font-size: 13px;
          }
        }
      `}</style>
        </>
    );
};

export default Alert;