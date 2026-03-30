// src/pages/inventory/steps/Step2_Variants.tsx
import { useState } from "react";
import { message } from "antd";
import { useProductFormStore } from "../../../core/redux/productFormStore";

const Step2_Variants = () => {
    const { variants, generateVariants } = useProductFormStore();
    const [colors, setColors] = useState<string[]>(["Kırmızı", "Siyah"]);
    const [sizes, setSizes] = useState<string[]>(["40", "41", "42"]);
    const [useColor, setUseColor] = useState(false);
    const [useSize, setUseSize] = useState(false);

    const handleGenerate = () => {
        const attrs: Record<string, string[]> = {};

        if (useColor && colors.length > 0) {
            attrs["Renk"] = colors;
        }
        if (useSize && sizes.length > 0) {
            attrs["Beden"] = sizes;
        }

        if (Object.keys(attrs).length === 0) {
            message.warning("En az bir özellik seçin");
            return;
        }

        generateVariants(attrs);
        message.success("Varyantlar oluşturuldu!");
    };

    return (
        <div className="card">
            <div className="card-body">
                <h5 className="mb-4">
                    <i className="feather icon-layers me-2" />
                    Varyant Oluşturucu
                </h5>

                <div className="mb-4">
                    <div className="form-check mb-3">
                        <input
                            className="form-check-input"
                            type="checkbox"
                            checked={useColor}
                            onChange={(e) => setUseColor(e.target.checked)}
                            id="useColor"
                        />
                        <label className="form-check-label" htmlFor="useColor">
                            Renk Özelliği Ekle
                        </label>
                    </div>

                    {useColor && (
                        <div className="ms-4 mb-3">
                            <label className="form-label">Renkler</label>
                            <input
                                type="text"
                                className="form-control"
                                value={colors.join(", ")}
                                onChange={(e) =>
                                    setColors(e.target.value.split(",").map((c) => c.trim()))
                                }
                                placeholder="Kırmızı, Siyah, Beyaz"
                            />
                        </div>
                    )}

                    <div className="form-check mb-3">
                        <input
                            className="form-check-input"
                            type="checkbox"
                            checked={useSize}
                            onChange={(e) => setUseSize(e.target.checked)}
                            id="useSize"
                        />
                        <label className="form-check-label" htmlFor="useSize">
                            Beden Özelliği Ekle
                        </label>
                    </div>

                    {useSize && (
                        <div className="ms-4 mb-3">
                            <label className="form-label">Bedenler</label>
                            <input
                                type="text"
                                className="form-control"
                                value={sizes.join(", ")}
                                onChange={(e) =>
                                    setSizes(e.target.value.split(",").map((s) => s.trim()))
                                }
                                placeholder="40, 41, 42, 43"
                            />
                        </div>
                    )}

                    <button
                        className="btn btn-primary"
                        onClick={handleGenerate}
                        disabled={!useColor && !useSize}
                    >
                        <i className="feather icon-zap me-2" />
                        Varyantları Oluştur
                    </button>
                </div>

                {variants.length > 0 && (
                    <div className="table-responsive">
                        <h6>Oluşturulan Varyantlar ({variants.length})</h6>
                        <table className="table table-bordered">
                            <thead>
                            <tr>
                                <th>#</th>
                                <th>İsim</th>
                                <th>SKU</th>
                                <th>Özellikler</th>
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
                                    <td>
                                        {Object.entries(v.attributes).map(([k, val]) => (
                                            <span key={k} className="badge bg-primary me-1">
                          {k}: {val}
                        </span>
                                        ))}
                                    </td>
                                </tr>
                            ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </div>
    );
};

export default Step2_Variants;