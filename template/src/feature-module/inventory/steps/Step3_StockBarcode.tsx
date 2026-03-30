// src/pages/inventory/steps/Step3_StockBarcode.tsx
import { useRef } from "react";
import { useProductFormStore } from "../../../core/redux/productFormStore";
import { message } from "antd";

type BarcodeType = "EAN13" | "CODE128" | "QR";

const BARCODE_TYPES: { value: BarcodeType; label: string }[] = [
    { value: "EAN13", label: "EAN-13" },
    { value: "CODE128", label: "Code 128" },
    { value: "QR", label: "QR Kod" },
];

/** EAN-13 formatında rastgele barkod üretir (13 hane, TR prefix 869) */
const generateEAN13 = () => {
    const prefix = "869";
    const mid = Math.floor(Math.random() * 1_000_000_000)
        .toString()
        .padStart(9, "0");
    const raw = prefix + mid;
    // Check digit hesapla
    let sum = 0;
    for (let i = 0; i < 12; i++) {
        sum += parseInt(raw[i]) * (i % 2 === 0 ? 1 : 3);
    }
    const check = (10 - (sum % 10)) % 10;
    return raw + check;
};

/** Code128 tarzı rastgele alfanümerik kod üretir */
const generateCode128 = () => {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let code = "";
    for (let i = 0; i < 12; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
};

/** QR için UUID benzeri string üretir */
const generateQR = () => {
    return "QR-" + Date.now().toString(36).toUpperCase() + "-" +
        Math.random().toString(36).slice(2, 8).toUpperCase();
};

const generateCode = (type: BarcodeType) => {
    if (type === "EAN13") return generateEAN13();
    if (type === "CODE128") return generateCode128();
    return generateQR();
};

/** SVG tabanlı basit barkod çizimi (EAN-13 / Code128 görünümü) */
const BarcodeSVG = ({ code, type }: { code: string; type: BarcodeType }) => {
    if (type === "QR") {
        // QR için grid göster
        const size = 6;
        const grid = 8;
        const cells: { x: number; y: number }[] = [];
        // Deterministik dolgu (char code tabanlı)
        for (let r = 0; r < grid; r++) {
            for (let c = 0; c < grid; c++) {
                const charCode = code.charCodeAt((r * grid + c) % code.length);
                if ((charCode + r + c) % 3 !== 0) {
                    cells.push({ x: c, y: r });
                }
            }
        }
        const total = grid * size;
        return (
            <svg width={total} height={total} style={{ display: "block" }}>
                <rect width={total} height={total} fill="white" />
                {cells.map((cell, i) => (
                    <rect
                        key={i}
                        x={cell.x * size}
                        y={cell.y * size}
                        width={size}
                        height={size}
                        fill="black"
                    />
                ))}
                {/* Köşe kareleri */}
                {[[0, 0], [0, 5], [5, 0]].map(([row, col], i) => (
                    <g key={`corner-${i}`}>
                        <rect x={col * size} y={row * size} width={size * 3} height={size * 3} fill="black" />
                        <rect x={col * size + size} y={row * size + size} width={size} height={size} fill="white" />
                    </g>
                ))}
            </svg>
        );
    }

    // Çizgi barkod (EAN-13 / Code128)
    const barWidth = 1.5;
    const height = 50;
    const bars: { x: number; w: number }[] = [];
    let x = 0;
    // Barkod çubuklarını kod karakterlerinden türet
    for (let i = 0; i < code.length; i++) {
        const charCode = code.charCodeAt(i);
        const w1 = (charCode % 3) + 1;
        const w2 = ((charCode >> 2) % 2) + 1;
        bars.push({ x, w: w1 * barWidth }); // siyah çubuk
        x += w1 * barWidth + w2 * barWidth; // boşluk
    }
    // Başlangıç/bitiş şeritleri
    const totalWidth = x + 4;

    return (
        <svg width={totalWidth} height={height + 12} style={{ display: "block" }}>
            <rect width={totalWidth} height={height + 12} fill="white" />
            {/* Başlangıç çubuğu */}
            <rect x={0} y={0} width={2} height={height} fill="black" />
            <rect x={3} y={0} width={1} height={height} fill="black" />
            {/* Veri çubukları */}
            {bars.map((bar, i) => (
                <rect key={i} x={bar.x + 5} y={0} width={bar.w} height={height} fill="black" />
            ))}
            {/* Bitiş çubuğu */}
            <rect x={totalWidth - 4} y={0} width={1} height={height} fill="black" />
            <rect x={totalWidth - 2} y={0} width={2} height={height} fill="black" />
            {/* Kod metni */}
            <text
                x={totalWidth / 2}
                y={height + 10}
                textAnchor="middle"
                fontSize="8"
                fontFamily="monospace"
                fill="black"
            >
                {code}
            </text>
        </svg>
    );
};

const Step3_StockBarcode = () => {
    const { variants } = useProductFormStore();
    const barcodeTypeRefs = useRef<Record<number, BarcodeType>>({});

    const getBarcodeType = (index: number): BarcodeType => {
        return barcodeTypeRefs.current[index] ?? "EAN13";
    };

    const updateVariantStock = (index: number, qty: number) => {
        const updated = [...variants];
        if (!updated[index].inventory) {
            updated[index].inventory = {
                warehouseCode: "WH-001",
                physicalQuantity: 0,
                minStockLevel: 10,
                reorderPoint: 20,
            };
        }
        updated[index].inventory!.physicalQuantity = qty;
        useProductFormStore.setState({ variants: updated });
    };

    const generateBarcode = (index: number, type?: BarcodeType) => {
        const barcodeType = type ?? getBarcodeType(index);
        const barcode = generateCode(barcodeType);
        const updated = [...variants];
        updated[index].barcodes = [
            {
                barcodeCode: barcode,
                barcodeType,
                isPrimary: true,
            },
        ];
        useProductFormStore.setState({ variants: updated });
        message.success(`${barcodeType} barkod oluşturuldu`);
    };

    const generateAllBarcodes = () => {
        const updated = variants.map((v, i) => {
            const type = getBarcodeType(i);
            return {
                ...v,
                barcodes: [
                    {
                        barcodeCode: generateCode(type),
                        barcodeType: type,
                        isPrimary: true,
                    },
                ],
            };
        });
        useProductFormStore.setState({ variants: updated });
        message.success(`${updated.length} varyant için barkod oluşturuldu`);
    };

    const copyBarcode = (code: string) => {
        navigator.clipboard.writeText(code).then(() => {
            message.success("Barkod kopyalandı");
        });
    };

    if (variants.length === 0) {
        return (
            <div className="card">
                <div className="card-body">
                    <h5 className="mb-4">
                        <i className="feather icon-package me-2" />
                        Stok ve Barkod
                    </h5>
                    <div className="alert alert-warning">
                        <i className="feather icon-alert-triangle me-2" />
                        Önce varyant oluşturun!
                    </div>
                </div>
            </div>
        );
    }

    const allBarcodesGenerated = variants.every(
        (v) => v.barcodes && v.barcodes.length > 0 && v.barcodes[0].barcodeCode
    );

    return (
        <div className="card">
            <div className="card-body">
                <div className="d-flex align-items-center justify-content-between mb-4">
                    <h5 className="mb-0">
                        <i className="feather icon-package me-2" />
                        Stok ve Barkod
                    </h5>
                    <button
                        className="btn btn-sm btn-primary"
                        onClick={generateAllBarcodes}
                    >
                        <i className="feather icon-zap me-1" />
                        Tüm Barkodları Oluştur
                    </button>
                </div>

                {!allBarcodesGenerated && (
                    <div className="alert alert-info py-2 mb-3">
                        <i className="feather icon-info me-2" />
                        Her varyant için barkod tipi seçip oluşturabilir veya "Tüm Barkodları Oluştur" ile toplu yapabilirsiniz.
                    </div>
                )}

                <div className="table-responsive">
                    <table className="table table-bordered align-middle">
                        <thead className="table-light">
                            <tr>
                                <th style={{ width: "40px" }}>#</th>
                                <th>Varyant</th>
                                <th style={{ width: "120px" }}>Stok</th>
                                <th style={{ width: "130px" }}>Barkod Tipi</th>
                                <th>Barkod</th>
                                <th style={{ width: "130px" }}>İşlem</th>
                            </tr>
                        </thead>
                        <tbody>
                            {variants.map((v, i) => {
                                const barcode = v.barcodes?.[0];
                                return (
                                    <tr key={i}>
                                        <td className="text-center text-muted">{i + 1}</td>
                                        <td>
                                            <span className="fw-semibold">{v.name}</span>
                                            <br />
                                            <small className="text-muted">{v.sku}</small>
                                        </td>
                                        <td>
                                            <input
                                                type="number"
                                                className="form-control form-control-sm"
                                                value={v.inventory?.physicalQuantity ?? 0}
                                                onChange={(e) =>
                                                    updateVariantStock(
                                                        i,
                                                        parseInt(e.target.value) || 0
                                                    )
                                                }
                                                min="0"
                                            />
                                        </td>
                                        <td>
                                            <select
                                                className="form-select form-select-sm"
                                                defaultValue="EAN13"
                                                onChange={(e) => {
                                                    barcodeTypeRefs.current[i] = e.target.value as BarcodeType;
                                                }}
                                            >
                                                {BARCODE_TYPES.map((bt) => (
                                                    <option key={bt.value} value={bt.value}>
                                                        {bt.label}
                                                    </option>
                                                ))}
                                            </select>
                                        </td>
                                        <td>
                                            {barcode ? (
                                                <div className="d-flex align-items-center gap-2">
                                                    <div
                                                        style={{
                                                            background: "#fff",
                                                            border: "1px solid #dee2e6",
                                                            borderRadius: "4px",
                                                            padding: "4px",
                                                            display: "inline-block",
                                                        }}
                                                    >
                                                        <BarcodeSVG
                                                            code={barcode.barcodeCode}
                                                            type={barcode.barcodeType as BarcodeType}
                                                        />
                                                    </div>
                                                    <div>
                                                        <span className="badge bg-secondary mb-1 d-block">
                                                            {barcode.barcodeType}
                                                        </span>
                                                        <button
                                                            className="btn btn-link btn-sm p-0 text-primary"
                                                            onClick={() => copyBarcode(barcode.barcodeCode)}
                                                            title="Kopyala"
                                                        >
                                                            <i className="feather icon-copy me-1" />
                                                            Kopyala
                                                        </button>
                                                    </div>
                                                </div>
                                            ) : (
                                                <span className="text-muted small">
                                                    <i className="feather icon-minus me-1" />
                                                    Oluşturulmadı
                                                </span>
                                            )}
                                        </td>
                                        <td>
                                            <button
                                                className="btn btn-sm btn-outline-primary w-100"
                                                onClick={() => generateBarcode(i)}
                                            >
                                                <i className="feather icon-refresh-cw me-1" />
                                                {barcode ? "Yenile" : "Oluştur"}
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
    );
};

export default Step3_StockBarcode;
