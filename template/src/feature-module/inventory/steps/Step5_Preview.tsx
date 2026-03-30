// src/pages/inventory/steps/Step5_Preview.tsx
import { useProductFormStore } from "../../../core/redux/productFormStore";

const Step5_Preview = () => {
    const { productName, slug, categoryId, brand, basePrice, variants } =
        useProductFormStore();

    const totalStock = variants.reduce(
        (sum, v) => sum + (v.inventory?.physicalQuantity || 0),
        0
    );

    return (
        <div className="card">
            <div className="card-body">
                <h5 className="mb-4">
                    <i className="feather icon-eye me-2" />
                    Önizleme
                </h5>

                <div className="row mb-4">
                    <div className="col-md-3">
                        <div className="card bg-primary text-white text-center">
                            <div className="card-body">
                                <h3>{variants.length}</h3>
                                <small>Toplam Varyant</small>
                            </div>
                        </div>
                    </div>
                    <div className="col-md-3">
                        <div className="card bg-success text-white text-center">
                            <div className="card-body">
                                <h3>{totalStock}</h3>
                                <small>Toplam Stok</small>
                            </div>
                        </div>
                    </div>
                    <div className="col-md-3">
                        <div className="card bg-info text-white text-center">
                            <div className="card-body">
                                <h3>{basePrice.toFixed(2)}</h3>
                                <small>Temel Fiyat</small>
                            </div>
                        </div>
                    </div>
                    <div className="col-md-3">
                        <div className="card bg-warning text-white text-center">
                            <div className="card-body">
                                <h3>
                                    {variants
                                        .filter(
                                            (v) => v.barcodes && v.barcodes.length > 0
                                        ).length}
                                </h3>
                                <small>Barkodlu</small>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="card bg-light mb-4">
                    <div className="card-body">
                        <h6>Ürün Bilgileri</h6>
                        <p>
                            <strong>Adı:</strong> {productName || "-"}
                        </p>
                        <p>
                            <strong>Slug:</strong> {slug || "-"}
                        </p>
                        <p>
                            <strong>Kategori:</strong> {categoryId || "-"}
                        </p>
                        <p>
                            <strong>Marka:</strong> {brand || "-"}
                        </p>
                    </div>
                </div>

                <h6>Varyantlar</h6>
                <div className="table-responsive">
                    <table className="table table-bordered">
                        <thead>
                        <tr>
                            <th>#</th>
                            <th>İsim</th>
                            <th>SKU</th>
                            <th>Stok</th>
                            <th>Barkod</th>
                        </tr>
                        </thead>
                        <tbody>
                        {variants.map((v, i) => (
                            <tr key={i}>
                                <td>{i + 1}</td>
                                <td>{v.name}</td>
                                <td>
                                    <code>{v.sku}</code>
                                </td>
                                <td>{v.inventory?.physicalQuantity || 0}</td>
                                <td>
                                    <small>{v.barcodes?.[0]?.barcodeCode || "-"}</small>
                                </td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default Step5_Preview;
