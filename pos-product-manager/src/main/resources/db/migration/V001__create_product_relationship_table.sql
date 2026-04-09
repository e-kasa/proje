-- Product Relationship Tablosu (Benzer/Alternatif/Tamamlayıcı Ürünler)
-- Ürünler arasındaki ilişkileri tutar (manuel olarak yönetici tarafından oluşturulur)

CREATE TABLE IF NOT EXISTS product_relationship (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- İlişki bilgileri
    source_product_id VARCHAR(255) NOT NULL,
    target_product_id VARCHAR(255) NOT NULL,
    relation_type VARCHAR(50) NOT NULL CHECK (relation_type IN ('SIMILAR', 'ALTERNATIVE', 'COMPLEMENTARY')),
    weight INTEGER DEFAULT 5 CHECK (weight >= 1 AND weight <= 10),

    -- Durum
    is_active BOOLEAN DEFAULT true,

    -- Audit
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(255),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    UNIQUE(source_product_id, target_product_id, relation_type),
    CONSTRAINT fk_source_product FOREIGN KEY (source_product_id) REFERENCES product(id) ON DELETE CASCADE,
    CONSTRAINT fk_target_product FOREIGN KEY (target_product_id) REFERENCES product(id) ON DELETE CASCADE
);

-- Indexes (Sorgu hızlandırma)
CREATE INDEX idx_product_relationship_source ON product_relationship(source_product_id);
CREATE INDEX idx_product_relationship_target ON product_relationship(target_product_id);
CREATE INDEX idx_product_relationship_active ON product_relationship(is_active);
CREATE INDEX idx_product_relationship_type ON product_relationship(relation_type);
CREATE INDEX idx_product_relationship_weight ON product_relationship(weight DESC);

-- Tablo açıklaması
COMMENT ON TABLE product_relationship IS 'Ürün benzerlikleri ve ilişkileri - Benzer ürün önerileri için kullanılır';
COMMENT ON COLUMN product_relationship.relation_type IS 'SIMILAR: Benzer ürün, ALTERNATIVE: Alternatif, COMPLEMENTARY: Tamamlayıcı';
COMMENT ON COLUMN product_relationship.weight IS 'Önerme ağırlığı (1-10, yüksek = daha fazla ön planda)';
