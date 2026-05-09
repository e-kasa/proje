package com.sedcore.customer.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Sprint 11e — Tenant-wide plaka arama sonucu.
 *
 * <p>AccountsList plaka modu için: müşteri ismi bilinmeden plaka prefix
 * arama → her plaka için müşteri + açık satış özeti.</p>
 *
 * <p>JPA constructor projection ile tek query'de aggregation
 * (CustomerVehicle LEFT JOIN Sale).</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleSearchResponse {

    private String id;
    private String customerId;
    private String customerName;
    private String plateDisplay;
    private String plateNormalized;
    private String make;
    private String model;
    /** Bu plakaya bağlı, iptal edilmemiş ve kalan tutarı > 0 olan satış sayısı. */
    private Long openSalesCount;
    /** SUM(totalAmount - paidAmount) — açık kalan toplam. */
    private BigDecimal openSalesAmount;
}
