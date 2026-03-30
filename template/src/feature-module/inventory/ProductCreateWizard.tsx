// src/pages/inventory/ProductCreateWizard.tsx
import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { message } from "antd";
import { all_routes } from "../../routes/all_routes";
import { useProductFormStore } from "../../core/redux/productFormStore";
import "../../assets/css/wizard.css";
// Steps
import Step1_BasicInfo from "./steps/Step1_BasicInfo";
import Step2_Variants from "./steps/Step2_Variants";
import Step3_StockBarcode from "./steps/Step3_StockBarcode";
import Step4_Images from "./steps/Step4_Images";
import Step5_Preview from "./steps/Step5_Preview";

const ProductCreateWizard = () => {
    const route = all_routes;
    const navigate = useNavigate();
    const [currentStep, setCurrentStep] = useState(0);
    const [loading, setLoading] = useState(false);

    const {
        productName,
        categoryId,
        basePrice,
        variants,
        reset,
    } = useProductFormStore();

    const steps = [
        {
            title: "Temel Bilgiler",
            icon: "info",
            component: <Step1_BasicInfo />,
        },
        {
            title: "Varyantlar",
            icon: "layers",
            component: <Step2_Variants />,
        },
        {
            title: "Stok & Barkod",
            icon: "package",
            component: <Step3_StockBarcode />,
        },
        {
            title: "Görseller",
            icon: "image",
            component: <Step4_Images />,
        },
        {
            title: "Önizleme",
            icon: "eye",
            component: <Step5_Preview />,
        },
    ];

    // Validation
    const validateCurrentStep = () => {
        switch (currentStep) {
            case 0: // Basic Info
                if (!productName) {
                    message.error("Ürün adı zorunludur");
                    return false;
                }
                if (!categoryId) {
                    message.error("Kategori seçimi zorunludur");
                    return false;
                }
                if (basePrice <= 0) {
                    message.error("Geçerli bir fiyat giriniz");
                    return false;
                }
                return true;

            case 1: // Variants
                if (variants.length === 0) {
                    message.error("En az bir varyant eklemelisiniz");
                    return false;
                }
                return true;

            case 2: // Stock
                const hasStockIssue = variants.some(
                    (v) => !v.inventory || v.inventory.physicalQuantity === undefined
                );
                if (hasStockIssue) {
                    message.warning("Bazı varyantlarda stok bilgisi eksik");
                }
                return true; // Warning ama devam edebilir

            default:
                return true;
        }
    };

    // Navigation
    const handleNext = () => {
        if (!validateCurrentStep()) {
            return;
        }
        setCurrentStep(currentStep + 1);
    };

    const handlePrev = () => {
        setCurrentStep(currentStep - 1);
    };

    // Submit
    const handleSubmit = async () => {
        setLoading(true);

        try {
            // Simulate API call
            await new Promise((resolve) => setTimeout(resolve, 2000));

            console.log("Payload:", {
                productName,
                categoryId,
                basePrice,
                variants,
            });

            message.success("Ürün başarıyla oluşturuldu!");
            reset();
            navigate(route.productlist);
        } catch (error: any) {
            message.error("Bir hata oluştu!");
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="page-wrapper">
            <div className="content">
                {/* Header */}
                <div className="page-header">
                    <div className="add-item d-flex">
                        <div className="page-title">
                            <h4>Yeni Ürün Ekle</h4>
                            <h6>
                                Adım {currentStep + 1} / {steps.length}
                            </h6>
                        </div>
                    </div>
                    <div className="page-btn">
                        <Link to={route.productlist} className="btn btn-secondary">
                            <i className="feather icon-arrow-left me-2" />
                            Geri Dön
                        </Link>
                    </div>
                </div>

                {/* Progress Bar */}
                <div className="wizard-progress mb-4">
                    <div className="progress mb-3" style={{ height: "8px" }}>
                        <div
                            className="progress-bar bg-primary"
                            style={{
                                width: `${((currentStep + 1) / steps.length) * 100}%`,
                            }}
                        />
                    </div>

                    {/* Steps */}
                    <ul className="wizard-steps">
                        {steps.map((step, index) => (
                            <li
                                key={index}
                                className={`step-item ${
                                    index === currentStep ? "active" : ""
                                } ${index < currentStep ? "completed" : ""}`}
                            >
                                <div className="step-icon">
                                    {index < currentStep ? (
                                        <i className="feather icon-check" />
                                    ) : (
                                        <i className={`feather icon-${step.icon}`} />
                                    )}
                                </div>
                                <div className="step-title">{step.title}</div>
                            </li>
                        ))}
                    </ul>
                </div>

                {/* Step Content */}
                <div className="wizard-content mb-4">
                    {steps[currentStep].component}
                </div>

                {/* Navigation Buttons */}
                <div className="wizard-footer">
                    <div className="d-flex align-items-center justify-content-between">
                        {/* Left: Back Button */}
                        <div>
                            {currentStep > 0 && (
                                <button
                                    type="button"
                                    className="btn btn-secondary"
                                    onClick={handlePrev}
                                >
                                    <i className="feather icon-arrow-left me-2" />
                                    Geri
                                </button>
                            )}
                        </div>

                        {/* Right: Cancel + Next/Submit */}
                        <div>
                            <button
                                type="button"
                                className="btn btn-light me-2"
                                onClick={() => {
                                    if (
                                        window.confirm(
                                            "Değişiklikler kaybolacak. Devam edilsin mi?"
                                        )
                                    ) {
                                        reset();
                                        navigate(route.productlist);
                                    }
                                }}
                            >
                                İptal
                            </button>

                            {currentStep < steps.length - 1 ? (
                                <button
                                    type="button"
                                    className="btn btn-primary"
                                    onClick={handleNext}
                                >
                                    İleri
                                    <i className="feather icon-arrow-right ms-2" />
                                </button>
                            ) : (
                                <button
                                    type="button"
                                    className="btn btn-success"
                                    onClick={handleSubmit}
                                    disabled={loading}
                                >
                                    {loading ? (
                                        <>
                                            <span className="spinner-border spinner-border-sm me-2" />
                                            Kaydediliyor...
                                        </>
                                    ) : (
                                        <>
                                            <i className="feather icon-save me-2" />
                                            Ürünü Kaydet
                                        </>
                                    )}
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ProductCreateWizard;