package com.sedcore.product.model;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.time.LocalDate;
import java.util.List;

/**
 * Toplu ürün giriş isteği.
 *
 * <p>Flutter'daki BatchEntryScreen'den gelen tüm satırları tek seferde gönderir:
 * <ul>
 *   <li>newProducts   → yeni ürünler: Product + Variant + OEM + CrossRef oluşturulur</li>
 *   <li>existingProducts → mevcut varyantlar: sadece stok + tedarikçi cari kaydı</li>
 * </ul>
 *
 * <p>Tüm kalemler için tek bir Purchase kaydı oluşturulur (fatura başlığı ortaktır).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BatchCreateRequest {

    // ── Ortak Satın Alma Başlığı ────────────────────────────────────────────

    @NotBlank(message = "Tedarikçi ID zorunludur")
    private String supplierId;

    @NotBlank(message = "Fatura numarası zorunludur")
    private String invoiceNumber;

    private String deliveryNoteNumber;

    @NotNull(message = "Satın alma tarihi zorunludur")
    private LocalDate purchaseDate;

    /**
     * Malın teslim alındığı lokasyon kodu: Store.code veya Warehouse.code
     * Örn: "STORE-01" (mağazaya) veya "WH-01" (depoya)
     */
    @NotBlank(message = "Lokasyon ID zorunludur")
    private String locationId;

    /** "STORE" veya "WAREHOUSE" */
    private String locationType;

    private String notes;

    // ── Ürün Kalemleri ──────────────────────────────────────────────────────

    /** Sistemde olmayan yeni ürünler — her biri CreateProduct akışından geçer */
    @Valid
    private List<BatchProductItem> newProducts;

    /** Sistemde mevcut varyantlar — sadece stok + cari güncellenir */
    @Valid
    private List<BatchExistingItem> existingProducts;
}
