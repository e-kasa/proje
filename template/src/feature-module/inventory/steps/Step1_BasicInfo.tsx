// src/pages/inventory/steps/Step1_BasicInfo.tsx
import { useState, useEffect } from "react";
import { useProductFormStore } from "../../../core/redux/productFormStore";
import CommonSelect from "../../../components/select/common-select";
import axios from "axios";

const Step1_BasicInfo = () => {
    const {
        productName,
        setProductName,
        slug,
        categoryId,
        setCategoryId,
        brand,
        setBrand,
        basePrice,
        setBasePrice,
    } = useProductFormStore();

    // State
    const [categories, setCategories] = useState<any[]>([]);
    const [brands, setBrands] = useState<any[]>([]);
    const [loadingCategories, setLoadingCategories] = useState(false);
    const [loadingBrands, setLoadingBrands] = useState(false);

    // Fetch Categories
    useEffect(() => {
        fetchCategories();
    }, []);

    // Fetch Brands
    useEffect(() => {
        fetchBrands();
    }, []);

    const fetchCategories = async () => {
        setLoadingCategories(true);
        try {
            const response = await axios.get("/api/v1/categories");

            // API response'una göre formatla
            const formattedCategories = response.data.map((cat: any) => ({
                value: cat.id || cat.categoryId,
                label: cat.name || cat.categoryName,
            }));

            setCategories(formattedCategories);
        } catch (error) {
            console.error("Kategoriler yüklenemedi:", error);

            // FALLBACK: Hata olursa dummy data
            setCategories([
                { value: "cat-1", label: "Spor Ayakkabı" },
                { value: "cat-2", label: "Elektronik" },
                { value: "cat-3", label: "Giyim" },
            ]);
        } finally {
            setLoadingCategories(false);
        }
    };

    const fetchBrands = async () => {
        setLoadingBrands(true);
        try {
            const response = await axios.get("/api/v1/brands");

            // API response'una göre formatla
            const formattedBrands = response.data.map((brand: any) => ({
                value: brand.id || brand.brandId,
                label: brand.name || brand.name
            }));

            setBrands(formattedBrands);
        } catch (error) {
            console.error("Markalar yüklenemedi:", error);

            // FALLBACK: Hata olursa dummy data
            setBrands([
                { value: "nike", label: "Nike" },
                { value: "adidas", label: "Adidas" },
                { value: "puma", label: "Puma" },
            ]);
        } finally {
            setLoadingBrands(false);
        }
    };

    return (
        <div className="card">
            <div className="card-body">
                <h5 className="mb-4">
                    <i className="feather icon-info me-2" />
                    Temel Ürün Bilgileri
                </h5>

                <div className="row">
                    {/* Ürün Adı */}
                    <div className="col-md-6 mb-3">
                        <label className="form-label">
                            Ürün Adı <span className="text-danger">*</span>
                        </label>
                        <input
                            type="text"
                            className="form-control"
                            value={productName}
                            onChange={(e) => setProductName(e.target.value)}
                            placeholder="Nike Air Max 270"
                        />
                    </div>

                    {/* Slug */}
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Slug (URL)</label>
                        <input
                            type="text"
                            className="form-control"
                            value={slug}
                            disabled
                            placeholder="Otomatik oluşturuldu"
                        />
                    </div>

                    {/* Kategori */}
                    <div className="col-md-6 mb-3">
                        <label className="form-label">
                            Kategori <span className="text-danger">*</span>
                        </label>
                        {loadingCategories ? (
                            <div className="form-control">
                                <span className="spinner-border spinner-border-sm me-2" />
                                Yükleniyor...
                            </div>
                        ) : (
                            <CommonSelect
                                className="w-100"
                                options={categories}
                                value={categoryId}
                                onChange={(e) => setCategoryId(e.value)}
                                placeholder="Kategori seçin"
                            />
                        )}
                    </div>

                    {/* Marka */}
                    <div className="col-md-6 mb-3">
                        <label className="form-label">Marka</label>
                        {loadingBrands ? (
                            <div className="form-control">
                                <span className="spinner-border spinner-border-sm me-2" />
                                Yükleniyor...
                            </div>
                        ) : (
                            <CommonSelect
                                className="w-100"
                                options={brands}
                                value={brand}
                                onChange={(e) => setBrand(e.value)}
                                placeholder="Marka seçin"
                            />
                        )}
                    </div>

                    {/* Temel Fiyat */}
                    <div className="col-md-6 mb-3">
                        <label className="form-label">
                            Temel Fiyat (TRY) <span className="text-danger">*</span>
                        </label>
                        <input
                            type="number"
                            className="form-control"
                            value={basePrice || ""}
                            onChange={(e) => setBasePrice(parseFloat(e.target.value) || 0)}
                            placeholder="999.99"
                            min="0"
                            step="0.01"
                        />
                    </div>
                </div>

                {/* Debug Info (Geliştirme için) */}
                {/*{process.env.NODE_ENV === 'development' && (*/}
                {/*    <div className="alert alert-info mt-3">*/}
                {/*        <small>*/}
                {/*            <strong>Debug:</strong> {categories.length} kategori, {brands.length} marka yüklendi*/}
                {/*        </small>*/}
                {/*    </div>*/}
                {/*)}*/}
            </div>
        </div>
    );
};

export default Step1_BasicInfo;