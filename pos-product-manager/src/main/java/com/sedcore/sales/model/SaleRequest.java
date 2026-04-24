package com.sedcore.sales.model;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SaleRequest {

    private String customerId; // null = peşin satış

    // Opsiyonel: backend otomatik üretir (POS'tan gönderilmeyebilir)
    private String saleNumber;

    /**
     * Satışın yapıldığı lokasyon kodu (genellikle Store.code).
     * Kasiyer için JWT storeId → POS provider'dan gelir.
     * Admin için POS ekranındaki mağaza seçiminden gelir.
     */
    private String locationId;

    /** STORE veya WAREHOUSE (genellikle STORE) */
    private String locationType;

    @Valid
    @NotEmpty(message = "En az bir ürün kalemi girilmelidir")
    private List<SaleItemRequest> items;

    @NotNull(message = "Ödenen tutar zorunludur (peşin satışta toplam tutar girin)")
    private BigDecimal paidAmount;

    private String notes;

    /**
     * Kredi limiti aşım durumunda override onayı.
     * Sadece ADMIN veya STORE_ADMIN rollerine sahip kullanıcılar set edebilir.
     * false/null → limit aşımında satış reddedilir (BUSINESS exception).
     * true + yetkili rol → satış geçer, audit log'a yazılır.
     * true + yetkisiz rol → 403/BUSINESS reddi (client defansif; UI butonu zaten göstermez).
     */
    @Builder.Default
    private Boolean overrideCreditLimit = false;
}
