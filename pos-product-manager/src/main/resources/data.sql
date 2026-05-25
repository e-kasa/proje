-- =====================================================================
-- POS Product Manager — Seed Data (Regenerated 2026-04-23)
-- =====================================================================
-- Yapi: 2 firma x 2 urun x 2 varyant; her alt senaryo icin 2'ser ornek.
--   SEDCORE  (AUTO_PARTS)  → oto1 prefix
--   SEDCORE1 (FOOTWEAR)    → elb1 prefix
-- Ortam: spring.jpa.hibernate.ddl-auto=create → her boot'ta fresh.
-- UUID formati: <3>-<4>-<4>-<4>-<4>-<12> = 36 char.
-- =====================================================================

-- ─── INVENTORY VIEW ───────────────────────────────────────────────────
DROP VIEW IF EXISTS inventory_view;
CREATE VIEW inventory_view AS
SELECT
    gen_random_uuid()::text   AS id,
    sm.company_code,
    'SYSTEM'::varchar         AS create_user,
    CURRENT_TIMESTAMP         AS create_time,
    CURRENT_TIMESTAMP         AS last_modified_time,
    NULL::varchar             AS update_user,
    sm.variant_id,
    sm.location_id,
    sm.location_type,
    SUM(CASE WHEN sm.movement_type IN ('PURCHASE_IN','SALE_RETURN_IN','SALE_CANCEL_IN','TRANSFER_IN','ADJUSTMENT_IN')
             THEN sm.quantity ELSE 0 END) -
    SUM(CASE WHEN sm.movement_type IN ('SALE_OUT','PURCHASE_RETURN_OUT','TRANSFER_OUT','ADJUSTMENT_OUT')
             THEN sm.quantity ELSE 0 END) AS physical_quantity
FROM stock_movements sm
GROUP BY sm.company_code, sm.variant_id, sm.location_id, sm.location_type;

-- =====================================================================
-- 1. STORES (2 per company)
-- =====================================================================
INSERT INTO stores
(id, create_user, company_code, create_time, last_modified_time,
 store_code, name, address, phone, is_active)
VALUES
    ('str-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'STORE-01','SEDCORE Merkez Magaza','Perpa, Istanbul','0212 000 00 01',true),
    ('str-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SUBE-01','SEDCORE Sube Magaza','Kadikoy, Istanbul','0216 000 00 01',true),
    ('str-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'STORE-02','SEDCORE1 Merkez Magaza','Zorlu AVM, Istanbul','0212 000 00 02',true),
    ('str-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SUBE-02','SEDCORE1 Sube Magaza','Akasya AVM, Istanbul','0216 000 00 02',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 2. WAREHOUSES (1 per company, each bound to main store)
-- =====================================================================
INSERT INTO warehouses
(id, create_user, company_code, create_time, last_modified_time,
 warehouse_code, name, store_code, address, is_active)
VALUES
    ('whs-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'WH-01','SEDCORE Ana Depo','STORE-01','Ikitelli OSB, Istanbul',true),
    ('whs-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'WH-02','SEDCORE Transit Depo','SUBE-01','Kartal, Istanbul',true),
    ('whs-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'WH-03','SEDCORE1 Ana Depo','STORE-02','Esenyurt, Istanbul',true),
    ('whs-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'WH-04','SEDCORE1 Transit Depo','SUBE-02','Maltepe, Istanbul',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 3. CATEGORIES (GLOBAL tablo, 2 main + 2 sub per sector = 6)
-- =====================================================================
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords)
VALUES
    ('cat-oto1-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Oto Yedek Parca','oto-yedek-parca','Oto yedek parca kategorisi',NULL,'build',1,0,'/oto-yedek-parca',
     false,'ACTIVE','{}'::jsonb,'Oto Yedek Parca','Oto parca','{oto,parca}'),
    ('cat-oto2-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fren Sistemi','fren-sistemi','Fren balata ve disk',NULL,'build',1,1,'/oto-yedek-parca/fren',
     false,'ACTIVE','{}'::jsonb,'Fren','Fren sistemi','{fren,balata}'),
    ('cat-oto2-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Filtreler','filtreler','Yag, hava, yakit filtreleri',NULL,'filter_alt',2,1,'/oto-yedek-parca/filtreler',
     false,'ACTIVE','{}'::jsonb,'Filtreler','Filtre cesitleri','{filtre,yag}'),
    ('cat-elb1-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Giyim','giyim','Giyim ana kategori',NULL,'checkroom',2,0,'/giyim',
     false,'ACTIVE','{}'::jsonb,'Giyim','Giyim urunleri','{giyim,moda}'),
    ('cat-elb2-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Ust Giyim','ust-giyim','T-shirt, gomlek, sweatshirt',NULL,'checkroom',1,1,'/giyim/ust',
     false,'ACTIVE','{}'::jsonb,'Ust Giyim','Ust giyim','{tshirt,sweat}'),
    ('cat-elb2-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Alt Giyim','alt-giyim','Pantolon ve etek',NULL,'checkroom',2,1,'/giyim/alt',
     false,'ACTIVE','{}'::jsonb,'Alt Giyim','Alt giyim','{pantolon}')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 4. COMPANY_CATEGORIES (her firma ana + 2 alt = 3)
-- =====================================================================
INSERT INTO company_categories
(id, create_user, company_code, create_time, last_modified_time,
 category_id, is_active, display_order)
VALUES
    ('ccp-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto1-0000-0000-0000-000000000001',true,1),
    ('ccp-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000001',true,2),
    ('ccp-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000002',true,3),
    ('cce-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb1-0000-0000-0000-000000000001',true,1),
    ('cce-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000001',true,2),
    ('cce-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000002',true,3)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 5. BRANDS (2 per company)
-- =====================================================================
INSERT INTO brands
(id, create_user, company_code, create_time, last_modified_time,
 name, code, description, is_active)
VALUES
    ('brd-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Bosch','BOSCH','Alman oto parca markasi',true),
    ('brd-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mann Filter','MANN','Filtre uzmani',true),
    ('brd-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Koton','KOTON','Turk giyim markasi',true),
    ('brd-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mavi','MAVI','Turk denim markasi',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 6. UNITS (2 per company)
-- =====================================================================
INSERT INTO units
(id, create_user, company_code, create_time, last_modified_time,
 code, name, symbol, type, is_active)
VALUES
    ('unt-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'ADET','Adet','adet','Sayilabilir',true),
    ('unt-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'TAKIM','Takim','tkm','Sayilabilir',true),
    ('unt-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'ADET','Adet','adet','Sayilabilir',true),
    ('unt-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'CIFT','Cift','cift','Sayilabilir',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 7. SUPPLIERS (2 per company: primary + secondary)
-- =====================================================================
INSERT INTO supplier
(id, create_user, company_code, create_time, last_modified_time,
 name, contact_name, phone, email, address, notes, customer_type,
 tax_number, tax_office, credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('sup-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Bosch Turkiye A.S.','Ahmet Yilmaz','0212 612 00 00','info@bosch.com.tr','Umraniye, Istanbul','Ana tedarikci','CORPORATE',
     '1234567890','Umraniye',500000.00,30,'NORMAL',true,false),
    ('sup-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Mann Filter Dagitim Ltd.','Mehmet Aksoy','0212 555 00 00','siparis@mannfilter.tr','Ikitelli OSB, Istanbul','Filtre ozel tedarikci','CORPORATE',
     '9876501234','Ikitelli',200000.00,45,'NORMAL',true,false),
    ('sup-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Koton Tekstil Toptan','Fatma Demir','0212 520 00 00','satis@koton-toptan.tr','Laleli, Istanbul','Ust giyim toptan','CORPORATE',
     '5555000001','Laleli',200000.00,30,'NORMAL',true,false),
    ('sup-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Mavi Denim Toptan','Ayse Kaya','0212 530 00 00','b2b@mavi-toptan.tr','Bayrampasa, Istanbul','Denim toptan tedarikci','CORPORATE',
     '5555000002','Bayrampasa',150000.00,45,'NORMAL',true,false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 8. SUPPLIER_ACCOUNTS (1:1 with supplier)
-- =====================================================================
INSERT INTO supplier_accounts
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, current_balance, total_debt, total_credit, overdue_amount,
 total_transaction_count, available_credit_limit, is_credit_limit_exceeded)
VALUES
    ('sac-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-oto1-0000-0000-0000-000000000001',    0.00, 4500.00, 4500.00, 0.00, 2, 500000.00, false),
    ('sac-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-oto1-0000-0000-0000-000000000002',-1575.00, 1800.00,  225.00, 0.00, 2, 198425.00, false),
    ('sac-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-elb1-0000-0000-0000-000000000001',    0.00, 8000.00, 8000.00, 0.00, 2, 200000.00, false),
    ('sac-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-elb1-0000-0000-0000-000000000002',-2400.00, 3000.00,  600.00, 0.00, 2, 147600.00, false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 9. CUSTOMERS (2 per company: normal + overdue)
-- =====================================================================
INSERT INTO customer
(id, create_user, company_code, create_time, last_modified_time,
 name, phone, email, address, notes, customer_type,
 tax_number, tax_office, credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('cus-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Usta Oto Servis Ltd.','0532 111 22 33','usta@email.com','Kadikoy, Istanbul','Duzenli kurumsal musteri','CORPORATE',
     '1112223334','Kadikoy',50000.00,30,'NORMAL',true,false),
    ('cus-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Adem Caliskan','0533 222 33 44','adem@email.com','Uskudar, Istanbul','Vadesi gecmis bireysel musteri','INDIVIDUAL',
     NULL,NULL,10000.00,30,'CRITICAL',true,false),
    ('cus-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Moda Butik A.S.','0533 444 55 66','info@modabutik.tr','Nisantasi, Istanbul','Kurumsal perakende alici','CORPORATE',
     '6667778889','Nisantasi',30000.00,30,'NORMAL',true,false),
    ('cus-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Zeynep Yilmaz','0534 555 66 77','zeynep@email.com','Bakirkoy, Istanbul','Vadesi gecmis bireysel','INDIVIDUAL',
     NULL,NULL,5000.00,30,'CRITICAL',true,false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 10. CUSTOMER_ACCOUNTS (1:1)
-- =====================================================================
INSERT INTO customer_accounts
(id, create_user, company_code, create_time, last_modified_time,
 customer_id, current_balance, total_debt, total_credit, overdue_amount,
 total_transaction_count, available_credit_limit, is_credit_limit_exceeded)
VALUES
    ('cac-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-oto1-0000-0000-0000-000000000001',    0.00, 1280.00, 1280.00,    0.00, 2, 50000.00, false),
    ('cac-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-oto1-0000-0000-0000-000000000002', 1450.00, 1450.00,    0.00, 1450.00, 1,  8550.00, false),
    ('cac-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-elb1-0000-0000-0000-000000000001',    0.00, 1800.00, 1800.00,    0.00, 2, 30000.00, false),
    ('cac-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-elb1-0000-0000-0000-000000000002',  950.00,  950.00,    0.00,  950.00, 1,  4050.00, false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 11. PRODUCTS (2 per company)
-- =====================================================================
INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    ('prd-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fren Balata Seti','FRN-BLT-001','fren-balata-seti','cat-oto2-0000-0000-0000-000000000001','Bosch','TAKIM',
     'On ve arka fren balata takimi',false,'ACTIVE'),
    ('prd-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Yag Filtresi','FLT-YAG-001','yag-filtresi','cat-oto2-0000-0000-0000-000000000002','Mann Filter','ADET',
     'Motor yag filtresi',false,'ACTIVE'),
    ('prd-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Basic Pamuk T-Shirt','TSH-BCK-001','basic-tshirt','cat-elb2-0000-0000-0000-000000000001','Koton','ADET',
     '%100 pamuk basic t-shirt',false,'ACTIVE'),
    ('prd-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Slim Fit Jean','JEN-SLM-001','slim-fit-jean','cat-elb2-0000-0000-0000-000000000002','Mavi','ADET',
     'Slim fit erkek jean pantolon',false,'ACTIVE')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 12. PRODUCT_VARIANTS (2 per product = 4 per company)
-- =====================================================================
INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, product_id, is_deleted, min_stock_level, shelf_location_code, additional_price)
VALUES
    ('var-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-ON','fren-balata-on','Fren Balata - On Aks','prd-oto1-0000-0000-0000-000000000001',false,5,'A-01',0.00),
    ('var-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-ARK','fren-balata-arka','Fren Balata - Arka Aks','prd-oto1-0000-0000-0000-000000000001',false,5,'A-02',0.00),
    ('var-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FLT-STD','yag-filtresi-std','Yag Filtresi - Standart','prd-oto1-0000-0000-0000-000000000002',false,10,'B-01',0.00),
    ('var-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FLT-PRM','yag-filtresi-prm','Yag Filtresi - Premium','prd-oto1-0000-0000-0000-000000000002',false,10,'B-02',0.00),
    ('var-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSH-S','tshirt-s','T-Shirt - Beden S','prd-elb1-0000-0000-0000-000000000001',false,10,'F-01',0.00),
    ('var-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSH-M','tshirt-m','T-Shirt - Beden M','prd-elb1-0000-0000-0000-000000000001',false,10,'F-02',0.00),
    ('var-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JEN-30','jean-30','Jean - Beden 30','prd-elb1-0000-0000-0000-000000000002',false,5,'G-01',0.00),
    ('var-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JEN-32','jean-32','Jean - Beden 32','prd-elb1-0000-0000-0000-000000000002',false,5,'G-02',0.00)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 13. BARCODES (1 per variant)
-- =====================================================================
INSERT INTO barcodes
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, barcode_code, barcode_type, is_primary, is_active, usage_count)
VALUES
    ('brc-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000001','8691000000001','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000002','8691000000002','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000003','8691000000003','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000004','8691000000004','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000001','8692000000001','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000002','8692000000002','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000003','8692000000003','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000004','8692000000004','EAN13',true,true,0)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 14. VARIANT_PRICING
-- =====================================================================
INSERT INTO variant_pricing
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, purchase_price, sale_price, currency,
 vat_rate, special_tax_rate, vat_included, withholding_tax_rate, tax_exempt)
VALUES
    ('vpr-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000001',180.00,320.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000002',160.00,290.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000003', 45.00, 85.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000004', 70.00,130.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000001', 80.00,149.00,'TRY', 8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000002', 80.00,149.00,'TRY', 8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000003',350.00,649.00,'TRY', 8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000004',350.00,649.00,'TRY', 8.00,0.00,false,0.00,false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 15. OEM_NUMBERS (auto parts only, 2 adet)
-- =====================================================================
INSERT INTO oem_numbers
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, oem_number, manufacturer, is_primary)
VALUES
    ('oem-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','0986AB1234','Bosch',true),
    ('oem-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','HU716/2X','Mann Filter',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 16. CROSS_REFERENCES (2 per company)
-- =====================================================================
INSERT INTO cross_references
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, cross_ref_number, cross_ref_brand, notes)
VALUES
    ('crf-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','TRW-GDB1330','TRW','TRW premium fren balata alternatifi'),
    ('crf-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','MAHLE-OX339-2D','Mahle','Mahle yag filtresi alternatifi'),
    ('crf-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000001','KOTON-BCK-S-ALT','Koton','Koton basic model alternatif'),
    ('crf-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000003','MAVI-SLM-30-ALT','Mavi','Mavi slim fit alternatif')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 17. VEHICLES (auto parts only, 2 adet)
-- =====================================================================
INSERT INTO vehicles
(id, create_user, company_code, create_time, last_modified_time,
 make, model, year_start, year_end, engine_type, fuel_type, body_type, platform_code, is_active)
VALUES
    ('veh-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Volkswagen','Golf VII',2012,2020,'1.6 TDI','Dizel','Hatchback','MQB',true),
    ('veh-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'BMW','320d F30',2012,2019,'2.0 d','Dizel','Sedan','F3x',true)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 18. VEHICLE_COMPATIBILITIES (2 adet)
-- =====================================================================
INSERT INTO vehicle_compatibilities
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, vehicle_id, is_verified, notes)
VALUES
    ('vcp-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','veh-oto1-0000-0000-0000-000000000001',true,'Golf VII on aks balata'),
    ('vcp-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','veh-oto1-0000-0000-0000-000000000002',true,'BMW 320d yag filtresi')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 19. PURCHASES (2 per company: COMPLETED + DISCOUNTED-with-claim)
-- =====================================================================
INSERT INTO purchases
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, purchase_date, invoice_number, delivery_note_number,
 invoice_amount, total_amount, paid_amount, discount_amount, shortage_amount,
 purchase_status, location_id, location_type, is_cancelled, notes)
VALUES
    ('pur-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '40 days',CURRENT_TIMESTAMP - INTERVAL '40 days',
     'sup-oto1-0000-0000-0000-000000000001',(CURRENT_DATE - INTERVAL '40 days')::date,'INV-BSH-001','IRS-BSH-001',
     4500.00,4500.00,4500.00,0.00,0.00,'COMPLETED','WH-01','WAREHOUSE',false,'Tam teslim - odendi'),
    ('pur-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'sup-oto1-0000-0000-0000-000000000002',(CURRENT_DATE - INTERVAL '10 days')::date,'INV-MNN-001','IRS-MNN-001',
     1800.00,1800.00,1575.00,225.00,225.00,'DISCOUNTED','WH-01','WAREHOUSE',false,'Eksik teslim - claim ile cozuldu'),
    ('pur-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'sup-elb1-0000-0000-0000-000000000001',(CURRENT_DATE - INTERVAL '35 days')::date,'INV-KTN-001','IRS-KTN-001',
     8000.00,8000.00,8000.00,0.00,0.00,'COMPLETED','WH-03','WAREHOUSE',false,'Tam teslim - odendi'),
    ('pur-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'sup-elb1-0000-0000-0000-000000000002',(CURRENT_DATE - INTERVAL '12 days')::date,'INV-MAV-001','IRS-MAV-001',
     3000.00,3000.00,2400.00,600.00,600.00,'DISCOUNTED','WH-03','WAREHOUSE',false,'Hasarli urun - claim ile cozuldu')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 20. SUPPLIER_CLAIMS (1 per company, DISCOUNT cozumlenmis)
-- =====================================================================
INSERT INTO supplier_claims
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, purchase_id, claim_amount, claim_reason, status, is_fully_resolved,
 resolved_amount, resolved_date, resolved_by, credit_note_number, notes)
VALUES
    ('scl-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'sup-oto1-0000-0000-0000-000000000002','pur-oto1-0000-0000-0000-000000000002',
     225.00,'SHORTAGE','RESOLVED_DISCOUNT',true,
     225.00,(CURRENT_DATE - INTERVAL '2 days')::date,'admin','CN-MNN-001','Eksik teslim - iskonto ile kapatildi'),
    ('scl-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '3 days',
     'sup-elb1-0000-0000-0000-000000000002','pur-elb1-0000-0000-0000-000000000002',
     600.00,'DAMAGE','RESOLVED_DISCOUNT',true,
     600.00,(CURRENT_DATE - INTERVAL '3 days')::date,'magaza_admin','CN-MAV-001','Hasarli urun - iskonto ile kapatildi')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 21. SUPPLIER_CLAIM_LINES (2 line per claim = 4 total)
-- =====================================================================
INSERT INTO supplier_claim_lines
(id, create_user, company_code, create_time, last_modified_time,
 claim_id, variant_id, variant_sku, product_name,
 expected_qty, received_qty, unit_price, line_amount,
 reason, resolved_qty, resolved_amount, is_resolved, notes)
VALUES
    ('sln-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'scl-oto1-0000-0000-0000-000000000001','var-oto1-0000-0000-0000-000000000003','FLT-STD','Yag Filtresi - Standart',
     25,20,45.00,225.00,'SHORTAGE',5,225.00,true,'5 adet eksik - iskonto'),
    ('sln-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'scl-oto1-0000-0000-0000-000000000001','var-oto1-0000-0000-0000-000000000004','FLT-PRM','Yag Filtresi - Premium',
     10,10,70.00,0.00,'SHORTAGE',0,0.00,true,'Kontrol lini - eksik yok'),
    ('sln-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '3 days',
     'scl-elb1-0000-0000-0000-000000000001','var-elb1-0000-0000-0000-000000000003','JEN-30','Jean - Beden 30',
     10,8,350.00,700.00,'DAMAGE',2,700.00,true,'2 adet hasarli - iskonto'),
    ('sln-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '3 days',
     'scl-elb1-0000-0000-0000-000000000001','var-elb1-0000-0000-0000-000000000004','JEN-32','Jean - Beden 32',
     8,8,350.00,0.00,'DAMAGE',0,0.00,true,'Kontrol lini - hasar yok')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 22. SALES (2 per company: CASH complete + CREDIT overdue)
-- =====================================================================
INSERT INTO sales
(id, create_user, company_code, create_time, last_modified_time,
 sale_number, sale_date, customer_id, total_amount, paid_amount,
 location_id, location_type, is_cancelled, has_return, returned_amount, notes)
VALUES
    ('sal-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'SAL-SED-0001',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'cus-oto1-0000-0000-0000-000000000001',1280.00,1280.00,'STORE-01','STORE',false,false,0.00,'Nakit satis - 4 adet Fren Balata On'),
    ('sal-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '50 days',CURRENT_TIMESTAMP - INTERVAL '50 days',
     'SAL-SED-0002',CURRENT_TIMESTAMP - INTERVAL '50 days',
     'cus-oto1-0000-0000-0000-000000000002',1450.00,0.00,'STORE-01','STORE',false,false,0.00,'Vadeli satis - vade gecmis (5 adet Arka)'),
    ('sal-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'SAL-S1-0001',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'cus-elb1-0000-0000-0000-000000000001',1800.00,1800.00,'STORE-02','STORE',false,false,0.00,'Kurumsal toptan satis - odendi'),
    ('sal-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '45 days',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'SAL-S1-0002',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'cus-elb1-0000-0000-0000-000000000002',950.00,0.00,'STORE-02','STORE',false,false,0.00,'Vadeli satis - vade gecmis')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 23. STOCK_TRANSFERS (2 per company: COMPLETED + IN_PROGRESS)
-- =====================================================================
INSERT INTO stock_transfers
(id, create_user, company_code, create_time, last_modified_time,
 from_location_id, from_location_type, to_location_id, to_location_type, notes)
VALUES
    ('stf-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days',
     'STORE-01','STORE','SUBE-01','STORE','Tamamlandi - Fren Balata On'),
    ('stf-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '1 days',CURRENT_TIMESTAMP - INTERVAL '1 days',
     'WH-01','WAREHOUSE','STORE-01','STORE','Surecte - Fren Balata Arka'),
    ('stf-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days',
     'STORE-02','STORE','SUBE-02','STORE','Tamamlandi - T-Shirt M'),
    ('stf-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'WH-03','WAREHOUSE','STORE-02','STORE','Surecte - Jean 32')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 24. STOCK_MOVEMENTS
-- =====================================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity,
 unit_price, purchase_id, sale_id, transfer_id)
VALUES
    ('stm-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '40 days',CURRENT_TIMESTAMP - INTERVAL '40 days',
     'var-oto1-0000-0000-0000-000000000001','WH-01','WAREHOUSE','PURCHASE_IN',25,180.00,'pur-oto1-0000-0000-0000-000000000001',NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '40 days',CURRENT_TIMESTAMP - INTERVAL '40 days',
     'var-oto1-0000-0000-0000-000000000002','WH-01','WAREHOUSE','PURCHASE_IN',30,160.00,'pur-oto1-0000-0000-0000-000000000001',NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'var-oto1-0000-0000-0000-000000000003','WH-01','WAREHOUSE','PURCHASE_IN',20, 45.00,'pur-oto1-0000-0000-0000-000000000002',NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'var-oto1-0000-0000-0000-000000000004','WH-01','WAREHOUSE','PURCHASE_IN',10, 70.00,'pur-oto1-0000-0000-0000-000000000002',NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '38 days',CURRENT_TIMESTAMP - INTERVAL '38 days',
     'var-oto1-0000-0000-0000-000000000001','WH-01','WAREHOUSE','TRANSFER_OUT',25,180.00,NULL,NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '38 days',CURRENT_TIMESTAMP - INTERVAL '38 days',
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','TRANSFER_IN',25,180.00,NULL,NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '38 days',CURRENT_TIMESTAMP - INTERVAL '38 days',
     'var-oto1-0000-0000-0000-000000000002','WH-01','WAREHOUSE','TRANSFER_OUT',30,160.00,NULL,NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000008','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '38 days',CURRENT_TIMESTAMP - INTERVAL '38 days',
     'var-oto1-0000-0000-0000-000000000002','STORE-01','STORE','TRANSFER_IN',30,160.00,NULL,NULL,NULL),
    ('stm-oto1-0000-0000-0000-000000000011','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_OUT',4,320.00,NULL,'sal-oto1-0000-0000-0000-000000000001',NULL),
    ('stm-oto1-0000-0000-0000-000000000012','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '50 days',CURRENT_TIMESTAMP - INTERVAL '50 days',
     'var-oto1-0000-0000-0000-000000000002','STORE-01','STORE','SALE_OUT',5,290.00,NULL,'sal-oto1-0000-0000-0000-000000000002',NULL),
    ('stm-oto1-0000-0000-0000-000000000021','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days',
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','TRANSFER_OUT',8,180.00,NULL,NULL,'stf-oto1-0000-0000-0000-000000000001'),
    ('stm-oto1-0000-0000-0000-000000000022','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days',
     'var-oto1-0000-0000-0000-000000000001','SUBE-01','STORE','TRANSFER_IN',8,180.00,NULL,NULL,'stf-oto1-0000-0000-0000-000000000001'),
    ('stm-oto1-0000-0000-0000-000000000023','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '1 days',CURRENT_TIMESTAMP - INTERVAL '1 days',
     'var-oto1-0000-0000-0000-000000000002','WH-01','WAREHOUSE','TRANSFER_OUT',10,160.00,NULL,NULL,'stf-oto1-0000-0000-0000-000000000002'),
    ('stm-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'var-elb1-0000-0000-0000-000000000001','WH-03','WAREHOUSE','PURCHASE_IN',40, 80.00,'pur-elb1-0000-0000-0000-000000000001',NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'var-elb1-0000-0000-0000-000000000002','WH-03','WAREHOUSE','PURCHASE_IN',60, 80.00,'pur-elb1-0000-0000-0000-000000000001',NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'var-elb1-0000-0000-0000-000000000003','WH-03','WAREHOUSE','PURCHASE_IN', 8,350.00,'pur-elb1-0000-0000-0000-000000000002',NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'var-elb1-0000-0000-0000-000000000004','WH-03','WAREHOUSE','PURCHASE_IN', 8,350.00,'pur-elb1-0000-0000-0000-000000000002',NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '33 days',CURRENT_TIMESTAMP - INTERVAL '33 days',
     'var-elb1-0000-0000-0000-000000000001','WH-03','WAREHOUSE','TRANSFER_OUT',40,80.00,NULL,NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '33 days',CURRENT_TIMESTAMP - INTERVAL '33 days',
     'var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','TRANSFER_IN',40,80.00,NULL,NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '33 days',CURRENT_TIMESTAMP - INTERVAL '33 days',
     'var-elb1-0000-0000-0000-000000000002','WH-03','WAREHOUSE','TRANSFER_OUT',60,80.00,NULL,NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '33 days',CURRENT_TIMESTAMP - INTERVAL '33 days',
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','TRANSFER_IN',60,80.00,NULL,NULL,NULL),
    ('stm-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','SALE_OUT', 8,149.00,NULL,'sal-elb1-0000-0000-0000-000000000001',NULL),
    ('stm-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','SALE_OUT', 4,149.00,NULL,'sal-elb1-0000-0000-0000-000000000001',NULL),
    ('stm-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '45 days',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','SALE_OUT', 2,149.00,NULL,'sal-elb1-0000-0000-0000-000000000002',NULL),
    ('stm-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '45 days',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'var-elb1-0000-0000-0000-000000000003','STORE-02','STORE','SALE_OUT', 2,326.00,NULL,'sal-elb1-0000-0000-0000-000000000002',NULL),
    ('stm-elb1-0000-0000-0000-000000000021','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days',
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','TRANSFER_OUT',10,80.00,NULL,NULL,'stf-elb1-0000-0000-0000-000000000001'),
    ('stm-elb1-0000-0000-0000-000000000022','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days',
     'var-elb1-0000-0000-0000-000000000002','SUBE-02','STORE','TRANSFER_IN',10,80.00,NULL,NULL,'stf-elb1-0000-0000-0000-000000000001'),
    ('stm-elb1-0000-0000-0000-000000000023','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'var-elb1-0000-0000-0000-000000000004','WH-03','WAREHOUSE','TRANSFER_OUT',5,350.00,NULL,NULL,'stf-elb1-0000-0000-0000-000000000002')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 25. STOCK_LEVELS (hesaplanmis net bakiyeler)
-- =====================================================================
INSERT INTO stock_levels
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, quantity, min_quantity, version)
VALUES
    ('slv-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE',13,5,0),
    ('slv-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','STORE-01','STORE',25,5,0),
    ('slv-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','SUBE-01','STORE',8,5,0),
    ('slv-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','WH-01','WAREHOUSE',20,10,0),
    ('slv-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','WH-01','WAREHOUSE',10,10,0),
    ('slv-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000001','STORE-02','STORE',36,10,0),
    ('slv-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE',40,10,0),
    ('slv-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000002','SUBE-02','STORE',10,10,0),
    ('slv-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000003','WH-03','WAREHOUSE',6,5,0),
    ('slv-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000004','WH-03','WAREHOUSE',3,5,0)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 26. PAYMENTS (2 per company: musteri tahsilat + tedarikciye odeme)
-- =====================================================================
INSERT INTO payments
(id, create_user, company_code, create_time, last_modified_time,
 payment_type, amount, payment_date,
 customer_id, supplier_id, sale_id, purchase_id,
 reference_number, bank_name, is_cancelled, is_verified,
 account_transaction_id, description)
VALUES
    ('pay-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'CASH',1280.00,CURRENT_TIMESTAMP - INTERVAL '20 days',
     'cus-oto1-0000-0000-0000-000000000001',NULL,'sal-oto1-0000-0000-0000-000000000001',NULL,
     'NKT-001',NULL,false,true,NULL,'Nakit satis tahsilati'),
    ('pay-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'BANK_TRANSFER',4500.00,CURRENT_TIMESTAMP - INTERVAL '35 days',
     NULL,'sup-oto1-0000-0000-0000-000000000001',NULL,'pur-oto1-0000-0000-0000-000000000001',
     'HVL-001','Ziraat Bankasi',false,true,NULL,'Bosch odemesi - havale'),
    ('pay-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'CREDIT_CARD',1800.00,CURRENT_TIMESTAMP - INTERVAL '18 days',
     'cus-elb1-0000-0000-0000-000000000001',NULL,'sal-elb1-0000-0000-0000-000000000001',NULL,
     'POS-001',NULL,false,true,NULL,'Kredi karti satis tahsilati'),
    ('pay-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days',
     'BANK_TRANSFER',8000.00,CURRENT_TIMESTAMP - INTERVAL '30 days',
     NULL,'sup-elb1-0000-0000-0000-000000000001',NULL,'pur-elb1-0000-0000-0000-000000000001',
     'HVL-002','Garanti BBVA',false,true,NULL,'Koton odemesi - havale')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 27. ACCOUNT_TRANSACTIONS
-- =====================================================================
INSERT INTO account_transactions
(id, create_user, company_code, create_time, last_modified_time,
 transaction_type, transaction_date, due_date,
 debit_amount, credit_amount, balance,
 customer_id, supplier_id, sale_id, purchase_id, payment_id,
 reference_type, reference_id, reference_number,
 description, is_overdue, is_cancelled, version)
VALUES
    ('atx-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'SALE',CURRENT_TIMESTAMP - INTERVAL '20 days',(CURRENT_DATE - INTERVAL '20 days')::date,
     1280.00,0.00,1280.00,
     'cus-oto1-0000-0000-0000-000000000001',NULL,'sal-oto1-0000-0000-0000-000000000001',NULL,NULL,
     'SALE','sal-oto1-0000-0000-0000-000000000001','SAL-SED-0001','Satis - 4 adet Fren Balata On',false,false,0),
    ('atx-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days',
     'COLLECTION',CURRENT_TIMESTAMP - INTERVAL '20 days',NULL,
     0.00,1280.00,0.00,
     'cus-oto1-0000-0000-0000-000000000001',NULL,'sal-oto1-0000-0000-0000-000000000001',NULL,'pay-oto1-0000-0000-0000-000000000001',
     'PAYMENT','pay-oto1-0000-0000-0000-000000000001','NKT-001','Tahsilat - nakit',false,false,0),
    ('atx-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '50 days',CURRENT_TIMESTAMP - INTERVAL '50 days',
     'SALE',CURRENT_TIMESTAMP - INTERVAL '50 days',(CURRENT_DATE - INTERVAL '20 days')::date,
     1450.00,0.00,1450.00,
     'cus-oto1-0000-0000-0000-000000000002',NULL,'sal-oto1-0000-0000-0000-000000000002',NULL,NULL,
     'SALE','sal-oto1-0000-0000-0000-000000000002','SAL-SED-0002','Vadeli satis - VADESI GECMIS',true,false,0),
    ('atx-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '40 days',CURRENT_TIMESTAMP - INTERVAL '40 days',
     'PURCHASE',CURRENT_TIMESTAMP - INTERVAL '40 days',(CURRENT_DATE - INTERVAL '10 days')::date,
     0.00,4500.00,-4500.00,
     NULL,'sup-oto1-0000-0000-0000-000000000001',NULL,'pur-oto1-0000-0000-0000-000000000001',NULL,
     'PURCHASE','pur-oto1-0000-0000-0000-000000000001','INV-BSH-001','Bosch alim',false,false,0),
    ('atx-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'SUPPLIER_PAYMENT',CURRENT_TIMESTAMP - INTERVAL '35 days',NULL,
     4500.00,0.00,0.00,
     NULL,'sup-oto1-0000-0000-0000-000000000001',NULL,'pur-oto1-0000-0000-0000-000000000001','pay-oto1-0000-0000-0000-000000000002',
     'PAYMENT','pay-oto1-0000-0000-0000-000000000002','HVL-001','Bosch odemesi',false,false,0),
    ('atx-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'PURCHASE',CURRENT_TIMESTAMP - INTERVAL '10 days',(CURRENT_DATE + INTERVAL '35 days')::date,
     0.00,1800.00,-1800.00,
     NULL,'sup-oto1-0000-0000-0000-000000000002',NULL,'pur-oto1-0000-0000-0000-000000000002',NULL,
     'PURCHASE','pur-oto1-0000-0000-0000-000000000002','INV-MNN-001','Mann Filter alim',false,false,0),
    ('atx-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP - INTERVAL '2 days',
     'DISCOUNT',CURRENT_TIMESTAMP - INTERVAL '2 days',NULL,
     225.00,0.00,-1575.00,
     NULL,'sup-oto1-0000-0000-0000-000000000002',NULL,'pur-oto1-0000-0000-0000-000000000002',NULL,
     'CLAIM','scl-oto1-0000-0000-0000-000000000001','CN-MNN-001','Claim iskonto - eksik yag filtresi',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'SALE',CURRENT_TIMESTAMP - INTERVAL '18 days',(CURRENT_DATE - INTERVAL '18 days')::date,
     1800.00,0.00,1800.00,
     'cus-elb1-0000-0000-0000-000000000001',NULL,'sal-elb1-0000-0000-0000-000000000001',NULL,NULL,
     'SALE','sal-elb1-0000-0000-0000-000000000001','SAL-S1-0001','Kurumsal satis',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days',
     'COLLECTION',CURRENT_TIMESTAMP - INTERVAL '18 days',NULL,
     0.00,1800.00,0.00,
     'cus-elb1-0000-0000-0000-000000000001',NULL,'sal-elb1-0000-0000-0000-000000000001',NULL,'pay-elb1-0000-0000-0000-000000000001',
     'PAYMENT','pay-elb1-0000-0000-0000-000000000001','POS-001','Kredi karti tahsilati',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '45 days',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'SALE',CURRENT_TIMESTAMP - INTERVAL '45 days',(CURRENT_DATE - INTERVAL '15 days')::date,
     950.00,0.00,950.00,
     'cus-elb1-0000-0000-0000-000000000002',NULL,'sal-elb1-0000-0000-0000-000000000002',NULL,NULL,
     'SALE','sal-elb1-0000-0000-0000-000000000002','SAL-S1-0002','Vadeli satis - VADESI GECMIS',true,false,0),
    ('atx-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '35 days',CURRENT_TIMESTAMP - INTERVAL '35 days',
     'PURCHASE',CURRENT_TIMESTAMP - INTERVAL '35 days',(CURRENT_DATE - INTERVAL '5 days')::date,
     0.00,8000.00,-8000.00,
     NULL,'sup-elb1-0000-0000-0000-000000000001',NULL,'pur-elb1-0000-0000-0000-000000000001',NULL,
     'PURCHASE','pur-elb1-0000-0000-0000-000000000001','INV-KTN-001','Koton alim',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days',
     'SUPPLIER_PAYMENT',CURRENT_TIMESTAMP - INTERVAL '30 days',NULL,
     8000.00,0.00,0.00,
     NULL,'sup-elb1-0000-0000-0000-000000000001',NULL,'pur-elb1-0000-0000-0000-000000000001','pay-elb1-0000-0000-0000-000000000002',
     'PAYMENT','pay-elb1-0000-0000-0000-000000000002','HVL-002','Koton odemesi',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'PURCHASE',CURRENT_TIMESTAMP - INTERVAL '12 days',(CURRENT_DATE + INTERVAL '33 days')::date,
     0.00,3000.00,-3000.00,
     NULL,'sup-elb1-0000-0000-0000-000000000002',NULL,'pur-elb1-0000-0000-0000-000000000002',NULL,
     'PURCHASE','pur-elb1-0000-0000-0000-000000000002','INV-MAV-001','Mavi alim',false,false,0),
    ('atx-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '3 days',CURRENT_TIMESTAMP - INTERVAL '3 days',
     'DISCOUNT',CURRENT_TIMESTAMP - INTERVAL '3 days',NULL,
     600.00,0.00,-2400.00,
     NULL,'sup-elb1-0000-0000-0000-000000000002',NULL,'pur-elb1-0000-0000-0000-000000000002',NULL,
     'CLAIM','scl-elb1-0000-0000-0000-000000000001','CN-MAV-001','Claim iskonto - hasarli jean',false,false,0)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 28. EXPENSES (2 per company)
-- =====================================================================
INSERT INTO expenses
(id, create_user, company_code, create_time, last_modified_time,
 title, amount, expense_date, description, category, payment_method, reference_number, status, is_deleted)
VALUES
    ('exp-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days',
     'Ocak Kirasi',15000.00,CURRENT_TIMESTAMP - INTERVAL '30 days','Magaza kirasi','Kira','BANK_TRANSFER','KIRA-001','PAID',false),
    ('exp-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days',
     'Elektrik Faturasi', 2500.00,CURRENT_TIMESTAMP - INTERVAL '15 days','Aylik elektrik','Fatura','CASH','ELK-001','PAID',false),
    ('exp-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days',
     'AVM Kirasi',25000.00,CURRENT_TIMESTAMP - INTERVAL '30 days','Zorlu AVM kira','Kira','BANK_TRANSFER','KIRA-002','PAID',false),
    ('exp-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'Temizlik Hizmeti', 3000.00,CURRENT_TIMESTAMP - INTERVAL '10 days','Aylik temizlik','Hizmet','BANK_TRANSFER','TMZ-001','PAID',false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 29. REVENUES (2 per company)
-- =====================================================================
INSERT INTO revenues
(id, create_user, company_code, create_time, last_modified_time,
 title, amount, revenue_date, description, category, payment_method, reference_number, is_deleted)
VALUES
    ('rev-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '60 days',CURRENT_TIMESTAMP - INTERVAL '60 days',
     'Eski Arac Satisi',8000.00,CURRENT_TIMESTAMP - INTERVAL '60 days','Servis araci satisi','Amortisman','CASH','ARC-001',false),
    ('rev-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days',
     'Mobil Servis Geliri', 500.00,CURRENT_TIMESTAMP - INTERVAL '10 days','Yerinde servis ucreti','Hizmet','CASH','SRV-001',false),
    ('rev-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '45 days',CURRENT_TIMESTAMP - INTERVAL '45 days',
     'Outlet Tasfiye',4500.00,CURRENT_TIMESTAMP - INTERVAL '45 days','Stok tasfiyesi','Kampanya','CASH','TSF-001',false),
    ('rev-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '8 days',CURRENT_TIMESTAMP - INTERVAL '8 days',
     'Magaza Reklam Geliri',1200.00,CURRENT_TIMESTAMP - INTERVAL '8 days','Vitrin reklam payi','Reklam','BANK_TRANSFER','RKL-001',false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 30. EMPLOYEES (2 per company)
-- =====================================================================
INSERT INTO employees
(id, create_user, company_code, create_time, last_modified_time,
 first_name, last_name, email, phone, department, position, hire_date, salary, status, is_deleted)
VALUES
    ('emp-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '180 days',CURRENT_TIMESTAMP - INTERVAL '180 days',
     'Ali','Yildiz','ali@sedcore.com','0533 111 11 11','Satis','Kasiyer',(CURRENT_DATE - INTERVAL '180 days')::date,18000.00,'ACTIVE',false),
    ('emp-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '90 days',CURRENT_TIMESTAMP - INTERVAL '90 days',
     'Mehmet','Kara','mehmet@sedcore.com','0533 222 22 22','Depo','Depo Sorumlusu',(CURRENT_DATE - INTERVAL '90 days')::date,20000.00,'ACTIVE',false),
    ('emp-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '160 days',CURRENT_TIMESTAMP - INTERVAL '160 days',
     'Ayse','Sahin','ayse@sedcore1.com','0534 111 11 11','Satis','Magaza Yoneticisi',(CURRENT_DATE - INTERVAL '160 days')::date,28000.00,'ACTIVE',false),
    ('emp-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '75 days',CURRENT_TIMESTAMP - INTERVAL '75 days',
     'Deniz','Celik','deniz@sedcore1.com','0534 222 22 22','Satis','Kasiyer',(CURRENT_DATE - INTERVAL '75 days')::date,19000.00,'ACTIVE',false)
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 31. COMPANY_SETTINGS (1 per company — sektor + genel bilgi + vergi default)
-- =====================================================================
-- Sprint 2026-05-25: defaultVatRate / defaultOtvRate / otvEnabled eklendi.
-- AUTO_PARTS  → vat=20, otv=18, otvEnabled=true
-- FOOTWEAR    → vat=10, otv=0,  otvEnabled=false
INSERT INTO company_settings
(id, create_user, company_code, create_time, last_modified_time,
 company_name, tax_number, tax_office, phone, email, address, city, country,
 currency, sector_type, default_vat_rate, default_otv_rate, otv_enabled)
VALUES
    ('cst-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Sedcore Oto Parca A.S.','1111222233','Perpa','0212 000 00 01','info@sedcore.com',
     'Perpa Ticaret Merkezi, Okmeydani','Istanbul','Turkiye','TRY','AUTO_PARTS',
     20.00, 18.00, true),
    ('cst-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Sedcore Giyim Magazasi','2222333344','Zincirlikuyu','0212 000 00 02','info@sedcore1.com',
     'Zorlu AVM, Levazim','Istanbul','Turkiye','TRY','FOOTWEAR',
     10.00, 0.00, false)
ON CONFLICT DO NOTHING;

-- Backfill: mevcut DB'lerde (ON CONFLICT skip eden satırlar) vergi default'larını seed et.
-- Idempotent — her boot'ta zararsız.
UPDATE company_settings
   SET default_vat_rate = 20.00, default_otv_rate = 18.00, otv_enabled = true
 WHERE id = 'cst-oto1-0000-0000-0000-000000000001'
   AND (default_vat_rate IS NULL OR default_otv_rate IS NULL);

UPDATE company_settings
   SET default_vat_rate = 10.00, default_otv_rate = 0.00, otv_enabled = false
 WHERE id = 'cst-elb1-0000-0000-0000-000000000001'
   AND (default_vat_rate IS NULL OR default_otv_rate IS NULL);

-- =====================================================================
-- 32. PRODUCT_RELATIONSHIP (her firma icin 2 oneri baglantisi)
-- =====================================================================
INSERT INTO product_relationship
(id, create_user, company_code, create_time, last_modified_time,
 source_product_id, target_product_id, relation_type, weight, is_active, created_by)
VALUES
    ('rel-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000001','prd-oto1-0000-0000-0000-000000000002','COMPLEMENTARY',8,true,'SYSTEM'),
    ('rel-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000002','prd-oto1-0000-0000-0000-000000000001','COMPLEMENTARY',7,true,'SYSTEM'),
    ('rel-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000001','prd-elb1-0000-0000-0000-000000000002','COMPLEMENTARY',9,true,'SYSTEM'),
    ('rel-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000002','prd-elb1-0000-0000-0000-000000000001','COMPLEMENTARY',8,true,'SYSTEM')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 33. SALE_RETURNS (1 iade per company: sal-1'den kismi)
-- =====================================================================
INSERT INTO sale_returns
(id, create_user, company_code, create_time, last_modified_time,
 return_number, sale_id, total_return_amount, reason, reason_label, notes, return_date)
VALUES
    ('srt-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days',
     'RET-SED-0001','sal-oto1-0000-0000-0000-000000000001',320.00,'WRONG_PART','Yanlis parca','1 adet Fren Balata On iadesi',
     CURRENT_TIMESTAMP - INTERVAL '15 days'),
    ('srt-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'RET-S1-0001','sal-elb1-0000-0000-0000-000000000001',298.00,'SIZE_MISMATCH','Beden uymadi','2 adet T-Shirt M iadesi',
     CURRENT_TIMESTAMP - INTERVAL '12 days')
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 34. SALE_RETURN_ITEMS
-- =====================================================================
INSERT INTO sale_return_items
(id, create_user, company_code, create_time, last_modified_time,
 sale_return_id, variant_id, quantity, unit_price, line_total, reason)
VALUES
    ('sri-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days',
     'srt-oto1-0000-0000-0000-000000000001','var-oto1-0000-0000-0000-000000000001',1,320.00,320.00,'WRONG_PART'),
    ('sri-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'srt-elb1-0000-0000-0000-000000000001','var-elb1-0000-0000-0000-000000000002',2,149.00,298.00,'SIZE_MISMATCH')
ON CONFLICT DO NOTHING;

-- Satis iade sonrasi has_return + returned_amount guncellemesi
UPDATE sales SET has_return = true, returned_amount = 320.00 WHERE id = 'sal-oto1-0000-0000-0000-000000000001';
UPDATE sales SET has_return = true, returned_amount = 298.00 WHERE id = 'sal-elb1-0000-0000-0000-000000000001';

-- Iade stok hareketleri
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity,
 unit_price, purchase_id, sale_id, transfer_id)
VALUES
    ('stm-oto1-0000-0000-0000-000000000030','SYSTEM','SEDCORE', CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days',
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_RETURN_IN',1,320.00,NULL,'sal-oto1-0000-0000-0000-000000000001',NULL),
    ('stm-elb1-0000-0000-0000-000000000030','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days',
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','SALE_RETURN_IN',2,149.00,NULL,'sal-elb1-0000-0000-0000-000000000001',NULL)
ON CONFLICT DO NOTHING;

-- Stock level update (iade sonrasi)
UPDATE stock_levels SET quantity = quantity + 1 WHERE id = 'slv-oto1-0000-0000-0000-000000000001';
UPDATE stock_levels SET quantity = quantity + 2 WHERE id = 'slv-elb1-0000-0000-0000-000000000002';

-- =====================================================================
-- 35. USER_DEF store_id eslestirmesi (security modulundeki kasiyerler)
-- =====================================================================
UPDATE user_def SET store_id = 'STORE-01' WHERE user_name = 'kasiyer';
UPDATE user_def SET store_id = 'SUBE-01'  WHERE user_name = 'kasiyer2';
UPDATE user_def SET store_id = 'STORE-02' WHERE user_name = 'giyim_kasiyer';

-- =====================================================================
-- 37. @Version normalize (Hibernate 6.x: NULL version -> 0)
-- Versioning.increment(NULL) NPE'sini onler.
-- =====================================================================
UPDATE products             SET version = 0 WHERE version IS NULL;
UPDATE product_variants     SET version = 0 WHERE version IS NULL;
UPDATE customer_accounts    SET version = 0 WHERE version IS NULL;
UPDATE sales                SET version = 0 WHERE version IS NULL;
UPDATE purchases            SET version = 0 WHERE version IS NULL;
UPDATE supplier_claims      SET version = 0 WHERE version IS NULL;
UPDATE supplier_claim_lines SET version = 0 WHERE version IS NULL;
UPDATE stock_movements      SET version = 0 WHERE version IS NULL;
UPDATE stock_transfers      SET version = 0 WHERE version IS NULL;
