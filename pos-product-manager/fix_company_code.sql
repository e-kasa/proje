-- ================================================
-- Company Code Kolonlarını Nullable Yapma
-- ================================================
-- Bu script tüm tablolardaki company_code kolonlarını
-- nullable yapar ve ilgili constraint'leri düzeltir

-- 1. CATEGORIES tablosu
ALTER TABLE categories DROP CONSTRAINT IF EXISTS uk_category_slug_company;
ALTER TABLE categories ALTER COLUMN company_code DROP NOT NULL;
UPDATE categories SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_category_company_code;
ALTER TABLE categories ADD CONSTRAINT uk_category_slug UNIQUE (slug);

-- 2. CATEGORY_VARIANTS tablosu
ALTER TABLE category_variants DROP CONSTRAINT IF EXISTS uk_category_variant_key;
ALTER TABLE category_variants ALTER COLUMN company_code DROP NOT NULL;
UPDATE category_variants SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_cv_company_code;
ALTER TABLE category_variants ADD CONSTRAINT uk_category_variant_key UNIQUE (category_id, variant_key);

-- 3. CATEGORY_ATTRIBUTES tablosu
ALTER TABLE category_attributes ALTER COLUMN company_code DROP NOT NULL;
UPDATE category_attributes SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_ca_company_code;

-- 4. PRODUCT_CATEGORIES tablosu
ALTER TABLE product_categories ALTER COLUMN company_code DROP NOT NULL;
UPDATE product_categories SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_pc_company_code;

-- 5. PRODUCT_CATEGORY_ATTRIBUTES tablosu
ALTER TABLE product_category_attributes ALTER COLUMN company_code DROP NOT NULL;
UPDATE product_category_attributes SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_pca_company_code;

-- 6. PRODUCTS tablosu
ALTER TABLE products ALTER COLUMN company_code DROP NOT NULL;
UPDATE products SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_product_company_code;

-- 7. PRODUCT_VARIANTS tablosu
ALTER TABLE product_variants ALTER COLUMN company_code DROP NOT NULL;
UPDATE product_variants SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_pv_company_code;

-- 8. BARCODES tablosu
ALTER TABLE barcodes ALTER COLUMN company_code DROP NOT NULL;
UPDATE barcodes SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_barcode_company_code;

-- 9. INVENTORY tablosu
ALTER TABLE inventory ALTER COLUMN company_code DROP NOT NULL;
UPDATE inventory SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_inventory_company_code;

-- 10. PRODUCT_MEDIA tablosu
ALTER TABLE product_media ALTER COLUMN company_code DROP NOT NULL;
UPDATE product_media SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_pm_company_code;

-- 11. PRODUCT_PRICES tablosu
ALTER TABLE product_prices ALTER COLUMN company_code DROP NOT NULL;
UPDATE product_prices SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_pp_company_code;

-- 12. SITES tablosu
ALTER TABLE sites ALTER COLUMN company_code DROP NOT NULL;
UPDATE sites SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_site_company_code;

-- 13. SITE_PRODUCTS tablosu
ALTER TABLE site_products ALTER COLUMN company_code DROP NOT NULL;
UPDATE site_products SET company_code = 'DEFAULT' WHERE company_code IS NULL;
DROP INDEX IF EXISTS idx_sp_company_code;

-- Başarı mesajı
SELECT 'Company code kolonları başarıyla nullable yapıldı!' AS result;
