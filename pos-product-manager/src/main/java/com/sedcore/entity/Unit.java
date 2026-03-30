package com.sedcore.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Unit (Birim) Entity — Firmaya özel ölçü birimleri.
 * Ürünlerde unit alanı bu tablodan gelir.
 */
@Entity
@Table(name = "units")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Unit extends TOpenSimpleCompanyEntity {

    @Column(name = "code", nullable = false, length = 20)
    private String code;       // Kısa kod: ADET, KG, LT, MT

    @Column(name = "name", nullable = false, length = 100)
    private String name;       // Uzun ad: Adet, Kilogram, Litre, Metre

    @Column(name = "symbol", length = 10)
    private String symbol;     // Sembol: pcs, kg, L, m

    @Column(name = "type", length = 50)
    private String type;       // Sayılabilir | Tartılabilir | Ölçülebilir

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}
