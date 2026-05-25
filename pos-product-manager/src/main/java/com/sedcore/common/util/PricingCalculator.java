package com.sedcore.common.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * Fiyat / vergi / iskonto hesaplama merkezi.
 *
 * <p>Satış ve alış servisleri (SaleServiceIntegrated, PurchaseServiceImpl) bu sınıfı kullanır.
 * Tek yerden hesap → iki servis arasında formül drift'i olmaz.
 *
 * <p><b>Hesap sırası (Türk vergi mevzuatı, plan kararı 2026-05-25):</b>
 * <pre>
 *   gross     = unitPrice × quantity
 *   discAmt   = gross × discRate / 100
 *   net       = gross − discAmt
 *   otvAmt    = net × otvRate / 100
 *   vatBase   = net + otvAmt              ← KDV matrahına ÖTV dahil
 *   vatAmt    = vatBase × vatRate / 100
 *   lineTotal = vatBase + vatAmt
 * </pre>
 *
 * <p><b>{@code vatIncluded=true} senaryosu</b>: {@code unitPrice} zaten KDV+ÖTV dahildir;
 * iskonto brüt (etiket) fiyat üzerinden uygulanır, sonra geri ayrıştırılır:
 * <pre>
 *   grossBrut = unitPrice × quantity
 *   discAmt   = grossBrut × discRate / 100     (etiket fiyat üzerinden)
 *   netBrut   = grossBrut − discAmt
 *   divisor   = (1 + otvRate/100) × (1 + vatRate/100)
 *   net       = netBrut / divisor              (KDV+ÖTV hariç net)
 *   otvAmt    = net × otvRate / 100
 *   vatAmt    = (net + otvAmt) × vatRate / 100
 *   lineTotal = netBrut                        (kullanıcı algısı: etiket fiyatı eksi iskonto)
 * </pre>
 *
 * <p>Yuvarlama: tüm para tutarları {@link RoundingMode#HALF_UP} ile 2 ondalık.
 * Oranlar {@link RoundingMode#HALF_UP} ile 4 ondalığa yuvarlanır (ara işlem hassasiyeti için).
 */
public final class PricingCalculator {

    /** Para tutarlarının ondalık sayısı (kuruş). */
    public static final int MONEY_SCALE = 2;

    /** Oran ara hesaplarda kullanılan ondalık sayı. */
    private static final int RATE_SCALE = 4;

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    private PricingCalculator() {
        // utility class — instantiate edilemez
    }

    /**
     * Bir satış/alış kalemini hesaplar.
     *
     * @param input giriş parametreleri (null oranlar ZERO sayılır, null miktar/birim fiyat IllegalArgumentException)
     * @return tüm tutarlar (BigDecimal, scale=2, HALF_UP)
     */
    public static LineCalculation calculate(LineInput input) {
        if (input == null) {
            throw new IllegalArgumentException("LineInput null olamaz");
        }
        if (input.getUnitPrice() == null) {
            throw new IllegalArgumentException("unitPrice null olamaz");
        }
        if (input.getQuantity() == null || input.getQuantity() < 0) {
            throw new IllegalArgumentException("quantity null veya negatif olamaz: " + input.getQuantity());
        }

        BigDecimal qty = BigDecimal.valueOf(input.getQuantity());
        BigDecimal unitPrice = input.getUnitPrice();
        BigDecimal discRate = nz(input.getDiscountRate());
        BigDecimal otvRate = nz(input.getOtvRate());
        BigDecimal vatRate = nz(input.getVatRate());
        boolean vatIncluded = Boolean.TRUE.equals(input.getVatIncluded());

        BigDecimal gross = unitPrice.multiply(qty).setScale(MONEY_SCALE, RoundingMode.HALF_UP);

        if (vatIncluded) {
            return calculateVatIncluded(gross, discRate, otvRate, vatRate);
        }
        return calculateVatExcluded(gross, discRate, otvRate, vatRate);
    }

    private static LineCalculation calculateVatExcluded(
            BigDecimal gross, BigDecimal discRate, BigDecimal otvRate, BigDecimal vatRate) {
        BigDecimal discAmt = percentOf(gross, discRate);
        BigDecimal net = gross.subtract(discAmt);
        BigDecimal otvAmt = percentOf(net, otvRate);
        BigDecimal vatBase = net.add(otvAmt);
        BigDecimal vatAmt = percentOf(vatBase, vatRate);
        BigDecimal lineTotal = vatBase.add(vatAmt);

        return LineCalculation.builder()
                .gross(gross)
                .discountAmount(discAmt)
                .net(net)
                .otvAmount(otvAmt)
                .vatBase(vatBase)
                .vatAmount(vatAmt)
                .lineTotal(lineTotal)
                .build();
    }

    private static LineCalculation calculateVatIncluded(
            BigDecimal grossBrut, BigDecimal discRate, BigDecimal otvRate, BigDecimal vatRate) {
        // İskonto etiket (KDV+ÖTV dahil) fiyat üzerinden — kullanıcı algısı
        BigDecimal discAmt = percentOf(grossBrut, discRate);
        BigDecimal netBrut = grossBrut.subtract(discAmt);

        // divisor = (1 + otv/100) × (1 + vat/100)
        BigDecimal otvFactor = BigDecimal.ONE.add(
                otvRate.divide(HUNDRED, RATE_SCALE, RoundingMode.HALF_UP));
        BigDecimal vatFactor = BigDecimal.ONE.add(
                vatRate.divide(HUNDRED, RATE_SCALE, RoundingMode.HALF_UP));
        BigDecimal divisor = otvFactor.multiply(vatFactor);

        BigDecimal net;
        if (divisor.compareTo(BigDecimal.ZERO) == 0) {
            // Hem KDV hem ÖTV %0 ise net = netBrut
            net = netBrut.setScale(MONEY_SCALE, RoundingMode.HALF_UP);
        } else {
            net = netBrut.divide(divisor, MONEY_SCALE, RoundingMode.HALF_UP);
        }

        BigDecimal otvAmt = percentOf(net, otvRate);
        BigDecimal vatBase = net.add(otvAmt);
        BigDecimal vatAmt = percentOf(vatBase, vatRate);

        // lineTotal = etiket fiyatı eksi iskonto (vatIncluded'da net brüt zaten kullanıcı algısı)
        BigDecimal lineTotal = netBrut.setScale(MONEY_SCALE, RoundingMode.HALF_UP);

        return LineCalculation.builder()
                .gross(grossBrut)
                .discountAmount(discAmt)
                .net(net)
                .otvAmount(otvAmt)
                .vatBase(vatBase)
                .vatAmount(vatAmt)
                .lineTotal(lineTotal)
                .build();
    }

    /** {@code base × rate / 100}, scale=2 HALF_UP. */
    private static BigDecimal percentOf(BigDecimal base, BigDecimal rate) {
        return base.multiply(rate).divide(HUNDRED, MONEY_SCALE, RoundingMode.HALF_UP);
    }

    /** null → BigDecimal.ZERO. */
    private static BigDecimal nz(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }

    // ─── DTO'lar ─────────────────────────────────────────────────────────

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    @ToString
    public static class LineInput {
        private BigDecimal unitPrice;
        private Integer quantity;
        /** İskonto oranı (%) — null = 0. */
        private BigDecimal discountRate;
        /** ÖTV oranı (%) — null = 0. */
        private BigDecimal otvRate;
        /** KDV oranı (%) — null = 0. */
        private BigDecimal vatRate;
        /** true → unitPrice KDV+ÖTV dahildir; null/false → hariç. */
        private Boolean vatIncluded;
    }

    @Getter
    @Builder
    @ToString
    public static class LineCalculation {
        /** Brüt: unitPrice × qty. */
        private final BigDecimal gross;
        /** İskonto tutarı. */
        private final BigDecimal discountAmount;
        /** İskontosuz, KDV/ÖTV hariç net (matrah). */
        private final BigDecimal net;
        /** ÖTV tutarı. */
        private final BigDecimal otvAmount;
        /** KDV matrahı = net + otvAmount. */
        private final BigDecimal vatBase;
        /** KDV tutarı. */
        private final BigDecimal vatAmount;
        /** Satır toplam (müşterinin ödeyeceği). */
        private final BigDecimal lineTotal;
    }
}
