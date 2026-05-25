package com.sedcore.common.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import com.sedcore.common.util.PricingCalculator.LineCalculation;
import com.sedcore.common.util.PricingCalculator.LineInput;

/**
 * {@link PricingCalculator} için kapsamlı senaryo testleri.
 *
 * <p>Plan {@code enchanted-wondering-chipmunk.md} § Verification:
 * en az 8 senaryo + edge case'ler.
 */
@DisplayName("PricingCalculator")
class PricingCalculatorTest {

    @Nested
    @DisplayName("KDV hariç (vatIncluded=false) — Türk standardı: iskonto → ÖTV → KDV")
    class VatExcluded {

        @Test
        @DisplayName("S1: iskonto=0, ÖTV=0, KDV=20% → 100 × 1.20 = 120")
        void scenario_onlyVat() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("100.00"))
                    .quantity(1)
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("100.00");
            assertThat(r.getDiscountAmount()).isEqualByComparingTo("0.00");
            assertThat(r.getNet()).isEqualByComparingTo("100.00");
            assertThat(r.getOtvAmount()).isEqualByComparingTo("0.00");
            assertThat(r.getVatBase()).isEqualByComparingTo("100.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("20.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("120.00");
        }

        @Test
        @DisplayName("S2: iskonto=%10, KDV=%20 → 100 → 90 → 108")
        void scenario_discountAndVat() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("100.00"))
                    .quantity(1)
                    .discountRate(new BigDecimal("10"))
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getDiscountAmount()).isEqualByComparingTo("10.00");
            assertThat(r.getNet()).isEqualByComparingTo("90.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("18.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("108.00");
        }

        @Test
        @DisplayName("S3 (AUTO_PARTS): iskonto=%10, ÖTV=%18, KDV=%20 → 127.44")
        void scenario_discountOtvVat() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("100.00"))
                    .quantity(1)
                    .discountRate(new BigDecimal("10"))
                    .otvRate(new BigDecimal("18"))
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("100.00");
            assertThat(r.getDiscountAmount()).isEqualByComparingTo("10.00");
            assertThat(r.getNet()).isEqualByComparingTo("90.00");
            assertThat(r.getOtvAmount()).isEqualByComparingTo("16.20");      // 90 × 0.18
            assertThat(r.getVatBase()).isEqualByComparingTo("106.20");        // 90 + 16.20
            assertThat(r.getVatAmount()).isEqualByComparingTo("21.24");       // 106.20 × 0.20
            assertThat(r.getLineTotal()).isEqualByComparingTo("127.44");
        }

        @Test
        @DisplayName("S4 (FOOTWEAR): iskonto=0, ÖTV=0, KDV=%10 → 110")
        void scenario_footwearStyle() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("100.00"))
                    .quantity(1)
                    .vatRate(new BigDecimal("10"))
                    .build());

            assertThat(r.getLineTotal()).isEqualByComparingTo("110.00");
            assertThat(r.getOtvAmount()).isEqualByComparingTo("0.00");
        }

        @Test
        @DisplayName("S5: vergiden muaf (ÖTV=0, KDV=0) → fiyat eşit")
        void scenario_taxExempt() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("50.00"))
                    .quantity(2)
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("100.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("0.00");
            assertThat(r.getOtvAmount()).isEqualByComparingTo("0.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("100.00");
        }

        @Test
        @DisplayName("S6: miktar=0 → tüm tutarlar 0")
        void scenario_zeroQuantity() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("100.00"))
                    .quantity(0)
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("0.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("0.00");
        }

        @Test
        @DisplayName("S7: tüm oranlar null → ZERO sayılır, formül çalışır")
        void scenario_allNullRates() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("80.00"))
                    .quantity(1)
                    .build());

            assertThat(r.getLineTotal()).isEqualByComparingTo("80.00");
            assertThat(r.getDiscountAmount()).isEqualByComparingTo("0.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("0.00");
        }

        @Test
        @DisplayName("S8: yuvarlama HALF_UP — 33.33 × 3 × 1.20 = 119.99 (kuruş hassasiyeti)")
        void scenario_roundingHalfUp() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("33.33"))
                    .quantity(3)
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("99.99");
            assertThat(r.getVatAmount()).isEqualByComparingTo("20.00");   // 99.99 × 0.20 = 19.998 → 20.00
            assertThat(r.getLineTotal()).isEqualByComparingTo("119.99");
        }

        @Test
        @DisplayName("S9: çoklu miktar + iskonto + KDV — 50 × 4 = 200, %5 isk, %20 KDV → 228")
        void scenario_multipleQuantity() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("50.00"))
                    .quantity(4)
                    .discountRate(new BigDecimal("5"))
                    .vatRate(new BigDecimal("20"))
                    .build());

            assertThat(r.getGross()).isEqualByComparingTo("200.00");
            assertThat(r.getDiscountAmount()).isEqualByComparingTo("10.00");
            assertThat(r.getNet()).isEqualByComparingTo("190.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("38.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("228.00");
        }
    }

    @Nested
    @DisplayName("KDV dahil (vatIncluded=true) — etiket fiyatından ayrıştırma")
    class VatIncluded {

        @Test
        @DisplayName("S10: KDV dahil 120 TL (vat=%20) → net 100, KDV 20, lineTotal=120")
        void scenario_vatIncluded_onlyVat() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("120.00"))
                    .quantity(1)
                    .vatRate(new BigDecimal("20"))
                    .vatIncluded(true)
                    .build());

            assertThat(r.getNet()).isEqualByComparingTo("100.00");
            assertThat(r.getVatAmount()).isEqualByComparingTo("20.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("120.00");
        }

        @Test
        @DisplayName("S11: KDV+ÖTV dahil etiket fiyat — iskonto etiket üzerinden")
        void scenario_vatIncluded_withOtvAndDiscount() {
            // Etiket: 141.60 TL (içinde %18 ÖTV + %20 KDV)
            // %10 iskonto → ödeme 127.44 TL (S3'le aynı sonuç)
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("141.60"))
                    .quantity(1)
                    .discountRate(new BigDecimal("10"))
                    .otvRate(new BigDecimal("18"))
                    .vatRate(new BigDecimal("20"))
                    .vatIncluded(true)
                    .build());

            assertThat(r.getDiscountAmount()).isEqualByComparingTo("14.16");
            assertThat(r.getLineTotal()).isEqualByComparingTo("127.44");
        }

        @Test
        @DisplayName("S12: KDV dahil ama oran=0 → net=brüt")
        void scenario_vatIncluded_zeroRates() {
            LineCalculation r = PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(new BigDecimal("75.00"))
                    .quantity(1)
                    .vatIncluded(true)
                    .build());

            assertThat(r.getNet()).isEqualByComparingTo("75.00");
            assertThat(r.getLineTotal()).isEqualByComparingTo("75.00");
        }
    }

    @Nested
    @DisplayName("Validation — hatalı girişlerde exception")
    class Validation {

        @Test
        @DisplayName("null input → IllegalArgumentException")
        void rejectNullInput() {
            assertThatThrownBy(() -> PricingCalculator.calculate(null))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("unitPrice null → IllegalArgumentException")
        void rejectNullUnitPrice() {
            assertThatThrownBy(() -> PricingCalculator.calculate(LineInput.builder()
                    .quantity(1)
                    .build()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("unitPrice");
        }

        @Test
        @DisplayName("quantity null → IllegalArgumentException")
        void rejectNullQuantity() {
            assertThatThrownBy(() -> PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(BigDecimal.TEN)
                    .build()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("quantity");
        }

        @Test
        @DisplayName("quantity negatif → IllegalArgumentException")
        void rejectNegativeQuantity() {
            assertThatThrownBy(() -> PricingCalculator.calculate(LineInput.builder()
                    .unitPrice(BigDecimal.TEN)
                    .quantity(-1)
                    .build()))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }
}
