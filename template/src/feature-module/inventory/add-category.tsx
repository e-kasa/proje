import React, { useState } from "react";
import { Link } from "react-router-dom";
import { all_routes } from "../../routes/all_routes";
import CommonFooter from "../../components/footer/commonFooter";
import RefreshIcon from "../../components/tooltip-content/refresh";
import CollapesIcon from "../../components/tooltip-content/collapes";
import CommonSelect from "../../components/select/common-select";
import { useSelector } from "react-redux";
import { Editor } from "primereact/editor";

interface VariantAttribute {
  value: string;
  label: string;
}

interface RootState {
  rootReducer: {
    variantattributes_data: {
      id: number;
      variant: string;
      values: string;
      createdon: string;
      status: string;
    }[];
  };
}

const AddCategory: React.FC = () => {
  const route = all_routes;

  // Form state
  const [categoryName, setCategoryName] = useState<string>("");
  const [categorySlug, setCategorySlug] = useState<string>("");
  const [description, setDescription] = useState<string>("");
  const [status, setStatus] = useState<boolean>(true);
  const [selectedVariants, setSelectedVariants] = useState<any[]>([]);
  const [variantValues, setVariantValues] = useState<{ [key: string]: string }>({});

  // Redux'tan varyant attribute verilerini çekme
  const variantAttributesData = useSelector(
    (state: RootState) => state.rootReducer.variantattributes_data
  );

  // Varyant attribute'ları select formatına dönüştürme
  const variantOptions: VariantAttribute[] = variantAttributesData.map((item) => ({
    value: item.variant,
    label: item.variant,
  }));

  // Slug otomatik oluşturma
  const handleCategoryNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const name = e.target.value;
    setCategoryName(name);

    // Otomatik slug oluştur
    const slug = name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/(^-|-$)/g, "");
    setCategorySlug(slug);
  };

  // Varyant ekleme
  const handleAddVariant = (selectedOption: any) => {
    if (selectedOption && !selectedVariants.find(v => v.value === selectedOption.value)) {
      setSelectedVariants([...selectedVariants, selectedOption]);
    }
  };

  // Varyant silme
  const handleRemoveVariant = (variantValue: string) => {
    setSelectedVariants(selectedVariants.filter(v => v.value !== variantValue));
    const newVariantValues = { ...variantValues };
    delete newVariantValues[variantValue];
    setVariantValues(newVariantValues);
  };

  // Varyant değerlerini güncelleme
  const handleVariantValueChange = (variantName: string, value: string) => {
    setVariantValues({
      ...variantValues,
      [variantName]: value,
    });
  };

  // Form gönderimi
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Form verilerini hazırlama
    const formData = {
      categoryName,
      categorySlug,
      description,
      status,
      variants: selectedVariants.map(variant => ({
        name: variant.value,
        values: variantValues[variant.value] || "",
      })),
    };

    console.log("Form Data:", formData);

    // Burada API çağrısı yapılacak
    // CategoryService.create(formData);

    alert("Kategori başarıyla oluşturuldu!");
  };

  return (
    <>
      <div className="page-wrapper">
        <div className="content">
          <div className="page-header">
            <div className="add-item d-flex">
              <div className="page-title">
                <h4>Kategori Ekle</h4>
                <h6>Varyant özellikli yeni kategori oluştur</h6>
              </div>
            </div>
            <ul className="table-top-head">
              <RefreshIcon />
              <CollapesIcon />
              <li>
                <div className="page-btn">
                  <Link to={route.categorylist} className="btn btn-secondary">
                    <i className="feather icon-arrow-left me-2" />
                    Kategori Listesine Dön
                  </Link>
                </div>
              </li>
            </ul>
          </div>

          {/* Add Category Form */}
          <form onSubmit={handleSubmit} className="add-product-form">
            <div className="add-product">
              {/* Temel Bilgiler */}
              <div className="accordion-item border mb-4">
                <h2 className="accordion-header" id="headingBasicInfo">
                  <div
                    className="accordion-button collapsed bg-white"
                    data-bs-toggle="collapse"
                    data-bs-target="#basicInfo"
                    aria-expanded="true"
                    aria-controls="basicInfo"
                  >
                    <div className="d-flex align-items-center justify-content-between flex-fill">
                      <h5 className="d-flex align-items-center">
                        <i className="feather icon-info text-primary me-2" />
                        <span>Temel Bilgiler</span>
                      </h5>
                    </div>
                  </div>
                </h2>
                <div
                  id="basicInfo"
                  className="accordion-collapse collapse show"
                  aria-labelledby="headingBasicInfo"
                >
                  <div className="accordion-body border-top">
                    <div className="row">
                      <div className="col-sm-6 col-12">
                        <div className="mb-3">
                          <label className="form-label">
                            Kategori Adı
                            <span className="text-danger ms-1">*</span>
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={categoryName}
                            onChange={handleCategoryNameChange}
                            placeholder="Örn: Elektronik"
                            required
                          />
                        </div>
                      </div>
                      <div className="col-sm-6 col-12">
                        <div className="mb-3">
                          <label className="form-label">
                            Kategori Slug
                            <span className="text-danger ms-1">*</span>
                          </label>
                          <input
                            type="text"
                            className="form-control"
                            value={categorySlug}
                            onChange={(e) => setCategorySlug(e.target.value)}
                            placeholder="Otomatik oluşturulur"
                            required
                          />
                        </div>
                      </div>
                    </div>

                    <div className="row">
                      <div className="col-12">
                        <div className="mb-3">
                          <label className="form-label">Açıklama</label>
                          <Editor
                            value={description}
                            onTextChange={(e: any) => setDescription(e.htmlValue)}
                            style={{ height: "200px" }}
                          />
                          <p className="fs-14 mt-1">Kategori hakkında detaylı açıklama</p>
                        </div>
                      </div>
                    </div>

                    <div className="row">
                      <div className="col-12">
                        <div className="mb-0">
                          <div className="status-toggle modal-status d-flex justify-content-between align-items-center">
                            <span className="status-label">
                              Durum<span className="text-danger ms-1">*</span>
                            </span>
                            <input
                              type="checkbox"
                              id="categoryStatus"
                              className="check"
                              checked={status}
                              onChange={(e) => setStatus(e.target.checked)}
                            />
                            <label htmlFor="categoryStatus" className="checktoggle" />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Varyant Attributes */}
              <div className="accordion-item border mb-4">
                <h2 className="accordion-header" id="headingVariants">
                  <div
                    className="accordion-button collapsed bg-white"
                    data-bs-toggle="collapse"
                    data-bs-target="#variants"
                    aria-expanded="true"
                    aria-controls="variants"
                  >
                    <div className="d-flex align-items-center justify-content-between flex-fill">
                      <h5 className="d-flex align-items-center">
                        <i className="feather icon-layers text-primary me-2" />
                        <span>Varyant Öznitelikleri</span>
                      </h5>
                    </div>
                  </div>
                </h2>
                <div
                  id="variants"
                  className="accordion-collapse collapse show"
                  aria-labelledby="headingVariants"
                >
                  <div className="accordion-body border-top">
                    <div className="row">
                      <div className="col-12">
                        <div className="mb-3">
                          <label className="form-label">
                            Varyant Seç
                          </label>
                          <CommonSelect
                            className="w-100"
                            options={variantOptions}
                            value={null}
                            onChange={(e) => handleAddVariant(e)}
                            placeholder="Varyant seçin ve ekleyin"
                            filter={true}
                          />
                          <p className="fs-14 mt-1 text-muted">
                            Bu kategoriye ait ürünlerin sahip olabileceği varyant özniteliklerini seçin (Renk, Beden, vb.)
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Seçili Varyantlar */}
                    {selectedVariants.length > 0 && (
                      <div className="row mt-4">
                        <div className="col-12">
                          <h6 className="mb-3">Seçili Varyantlar</h6>
                          <div className="table-responsive">
                            <table className="table table-bordered">
                              <thead>
                                <tr>
                                  <th style={{ width: "30%" }}>Varyant Adı</th>
                                  <th style={{ width: "60%" }}>Değerler</th>
                                  <th style={{ width: "10%" }}>İşlem</th>
                                </tr>
                              </thead>
                              <tbody>
                                {selectedVariants.map((variant, index) => {
                                  // Redux'tan ilgili varyantın mevcut değerlerini getir
                                  const variantData = variantAttributesData.find(
                                    (v) => v.variant === variant.value
                                  );

                                  return (
                                    <tr key={index}>
                                      <td>
                                        <div className="d-flex align-items-center">
                                          <i className="feather icon-tag text-primary me-2" />
                                          <strong>{variant.label}</strong>
                                        </div>
                                      </td>
                                      <td>
                                        <input
                                          type="text"
                                          className="form-control"
                                          placeholder="Değerleri virgülle ayırın (Örn: Kırmızı, Mavi, Yeşil)"
                                          value={variantValues[variant.value] || variantData?.values || ""}
                                          onChange={(e) =>
                                            handleVariantValueChange(variant.value, e.target.value)
                                          }
                                        />
                                        <small className="text-muted">
                                          Varsayılan: {variantData?.values || "Değer yok"}
                                        </small>
                                      </td>
                                      <td className="text-center">
                                        <button
                                          type="button"
                                          className="btn btn-sm btn-outline-danger"
                                          onClick={() => handleRemoveVariant(variant.value)}
                                        >
                                          <i className="feather icon-trash-2" />
                                        </button>
                                      </td>
                                    </tr>
                                  );
                                })}
                              </tbody>
                            </table>
                          </div>
                        </div>
                      </div>
                    )}

                    {selectedVariants.length === 0 && (
                      <div className="alert alert-info">
                        <i className="feather icon-info me-2" />
                        Henüz varyant eklenmedi. Yukarıdan varyant seçerek ekleyebilirsiniz.
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* Form Buttons */}
            <div className="col-lg-12">
              <div className="d-flex align-items-center justify-content-end mb-4">
                <Link
                  to={route.categorylist}
                  className="btn btn-secondary me-2"
                >
                  İptal
                </Link>
                <button type="submit" className="btn btn-primary">
                  <i className="feather icon-save me-2" />
                  Kategori Kaydet
                </button>
              </div>
            </div>
          </form>
          {/* /Add Category Form */}
        </div>
        <CommonFooter />
      </div>
    </>
  );
};

export default AddCategory;
