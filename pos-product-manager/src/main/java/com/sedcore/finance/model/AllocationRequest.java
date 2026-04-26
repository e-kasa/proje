package com.sedcore.finance.model;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Bir Payment'in tek bir satışa (veya genel cariye) yapılan dağıtım kaydı.
 *
 * Sprint 7'de eklendi (Sale-Payment many-to-many için).
 *
 * Kurallar:
 *   - saleId null = "genel ödeme" (belirli satışa değil, cari bakiyeye)
 *   - amount > 0
 *   - PaymentRequest.allocations listesinde SUM(amount) == PaymentRequest.amount
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AllocationRequest {

    /** Hangi satışa? null = genel cari ödemesi */
    private String saleId;

    @NotNull(message = "Allocation tutarı zorunludur")
    @DecimalMin(value = "0.01", message = "Allocation tutarı 0'dan büyük olmalıdır")
    private BigDecimal amount;
}
