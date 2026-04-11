package com.sedcore.product.entity;

import com.towpen.base.db.model.TOpenSimpleCompanyEntity;
import jakarta.persistence.*;
import lombok.*;

/**
 * Brand (Marka) Entity — Firmaya özel marka listesi.
 * Ürünlerde brand alanı bu tablodan gelir.
 */
@Entity
@Table(name = "brands")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Brand extends TOpenSimpleCompanyEntity {

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "code", length = 50)
    private String code;

    @Column(name = "description", length = 500)
    private String description;

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}
