// src/pages/inventory/steps/Step4_Images.tsx
import { useRef, useState } from "react";
import { useProductFormStore } from "../../../core/redux/productFormStore";
import { message } from "antd";

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const Step4_Images = () => {
    const { images, addImages, removeImage, setPrimaryImage } = useProductFormStore();
    const [isDragging, setIsDragging] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const processFiles = (files: FileList | null) => {
        if (!files || files.length === 0) return;

        const validFiles: File[] = [];
        Array.from(files).forEach((file) => {
            if (!ALLOWED_TYPES.includes(file.type)) {
                message.error(`${file.name}: Desteklenmeyen format (JPG, PNG, WEBP, GIF)`);
                return;
            }
            if (file.size > MAX_FILE_SIZE) {
                message.error(`${file.name}: Dosya boyutu 5MB'dan büyük`);
                return;
            }
            validFiles.push(file);
        });

        if (validFiles.length > 0) {
            addImages(validFiles);
            message.success(`${validFiles.length} görsel eklendi`);
        }
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(false);
        processFiles(e.dataTransfer.files);
    };

    const handleDragOver = (e: React.DragEvent) => {
        e.preventDefault();
        setIsDragging(true);
    };

    const handleDragLeave = () => setIsDragging(false);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        processFiles(e.target.files);
        // Input'u sıfırla ki aynı dosya tekrar seçilebilsin
        e.target.value = "";
    };

    const handleRemove = (id: string) => {
        removeImage(id);
        message.info("Görsel kaldırıldı");
    };

    const handleSetPrimary = (id: string) => {
        setPrimaryImage(id);
        message.success("Ana görsel güncellendi");
    };

    return (
        <div className="card">
            <div className="card-body">
                <h5 className="mb-4">
                    <i className="feather icon-image me-2" />
                    Ürün Görselleri
                </h5>

                {/* Upload Zone */}
                <div
                    className={`border-2 rounded p-5 text-center mb-4 ${
                        isDragging
                            ? "border-primary bg-primary bg-opacity-10"
                            : "border-dashed"
                    }`}
                    style={{
                        border: isDragging
                            ? "2px dashed #4e73df"
                            : "2px dashed #d1d3e2",
                        cursor: "pointer",
                        transition: "all 0.2s",
                    }}
                    onDrop={handleDrop}
                    onDragOver={handleDragOver}
                    onDragLeave={handleDragLeave}
                    onClick={() => fileInputRef.current?.click()}
                >
                    <i
                        className={`feather icon-upload-cloud mb-3 d-block ${
                            isDragging ? "text-primary" : "text-muted"
                        }`}
                        style={{ fontSize: "2.5rem" }}
                    />
                    <p className="mb-1 fw-semibold">
                        Görselleri buraya sürükleyin veya tıklayın
                    </p>
                    <small className="text-muted">
                        JPG, PNG, WEBP, GIF — Maks. 5MB/dosya
                    </small>
                    <input
                        ref={fileInputRef}
                        type="file"
                        accept="image/*"
                        multiple
                        className="d-none"
                        onChange={handleFileChange}
                    />
                </div>

                {/* Image Grid */}
                {images.length > 0 ? (
                    <>
                        <div className="d-flex align-items-center justify-content-between mb-3">
                            <span className="text-muted small">
                                {images.length} görsel seçildi —{" "}
                                <span className="text-warning">
                                    <i className="feather icon-star me-1" />
                                    olan ana görseldir
                                </span>
                            </span>
                            <button
                                className="btn btn-sm btn-outline-danger"
                                onClick={() => {
                                    if (window.confirm("Tüm görseller kaldırılsın mı?")) {
                                        images.forEach((img) => removeImage(img.id));
                                    }
                                }}
                            >
                                <i className="feather icon-trash-2 me-1" />
                                Tümünü Kaldır
                            </button>
                        </div>

                        <div className="row g-3">
                            {images.map((img) => (
                                <div key={img.id} className="col-6 col-md-3 col-lg-2">
                                    <div
                                        className={`position-relative rounded overflow-hidden ${
                                            img.isPrimary
                                                ? "border border-2 border-warning"
                                                : "border"
                                        }`}
                                        style={{ aspectRatio: "1 / 1" }}
                                    >
                                        {/* Önizleme */}
                                        <img
                                            src={img.preview}
                                            alt={img.file.name}
                                            style={{
                                                width: "100%",
                                                height: "100%",
                                                objectFit: "cover",
                                            }}
                                        />

                                        {/* Primary rozeti */}
                                        {img.isPrimary && (
                                            <span
                                                className="position-absolute top-0 start-0 badge bg-warning text-dark m-1"
                                                style={{ fontSize: "10px" }}
                                            >
                                                <i className="feather icon-star me-1" />
                                                Ana
                                            </span>
                                        )}

                                        {/* Aksiyon butonları */}
                                        <div
                                            className="position-absolute bottom-0 start-0 end-0 d-flex justify-content-between p-1"
                                            style={{
                                                background:
                                                    "linear-gradient(transparent, rgba(0,0,0,0.6))",
                                            }}
                                        >
                                            {!img.isPrimary && (
                                                <button
                                                    className="btn btn-sm btn-warning py-0 px-1"
                                                    title="Ana görsel yap"
                                                    onClick={() => handleSetPrimary(img.id)}
                                                    style={{ fontSize: "11px" }}
                                                >
                                                    <i className="feather icon-star" />
                                                </button>
                                            )}
                                            <button
                                                className="btn btn-sm btn-danger py-0 px-1 ms-auto"
                                                title="Kaldır"
                                                onClick={() => handleRemove(img.id)}
                                                style={{ fontSize: "11px" }}
                                            >
                                                <i className="feather icon-x" />
                                            </button>
                                        </div>
                                    </div>
                                    <small
                                        className="d-block text-truncate text-muted mt-1"
                                        style={{ fontSize: "10px" }}
                                        title={img.file.name}
                                    >
                                        {img.file.name}
                                    </small>
                                </div>
                            ))}

                            {/* Ekle butonu (grid içinde) */}
                            <div className="col-6 col-md-3 col-lg-2">
                                <div
                                    className="border border-dashed rounded d-flex flex-column align-items-center justify-content-center text-muted"
                                    style={{
                                        aspectRatio: "1 / 1",
                                        cursor: "pointer",
                                        border: "2px dashed #d1d3e2",
                                    }}
                                    onClick={() => fileInputRef.current?.click()}
                                >
                                    <i className="feather icon-plus" style={{ fontSize: "1.5rem" }} />
                                    <small>Ekle</small>
                                </div>
                            </div>
                        </div>
                    </>
                ) : (
                    <div className="alert alert-secondary text-center">
                        <i className="feather icon-image me-2" />
                        Henüz görsel eklenmedi. Ürün görseli eklemek için yukarıya sürükleyin veya tıklayın.
                    </div>
                )}
            </div>
        </div>
    );
};

export default Step4_Images;
