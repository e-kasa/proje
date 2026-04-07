-- ================================================
-- POS Product Manager - Seed Data
-- Parçacı (5 ürün) + Elbise Mağazası (5 ürün)
-- Tüm UUID'ler max 36 karakter (varchar(36) uyumlu)
-- ================================================

-- ================================================
-- INVENTORY VIEW
-- ================================================
DROP TABLE IF EXISTS inventory_view;
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
    sm.store_id,
    sm.warehouse_id,
    SUM(CASE WHEN sm.movement_type IN ('PURCHASE_IN','SALE_RETURN_IN','SALE_CANCEL_IN','TRANSFER_IN','ADJUSTMENT_IN')
             THEN sm.quantity ELSE 0 END) -
    SUM(CASE WHEN sm.movement_type IN ('SALE_OUT','PURCHASE_RETURN_OUT','TRANSFER_OUT','ADJUSTMENT_OUT')
             THEN sm.quantity ELSE 0 END) AS physical_quantity
FROM stock_movements sm
GROUP BY sm.company_code, sm.variant_id, sm.store_id, sm.warehouse_id;

-- ================================================
-- 0. STORES & WAREHOUSES
-- ================================================
INSERT INTO stores
(id, create_user, company_code, create_time, last_modified_time,
 store_code, name, address, phone, is_active)
VALUES
    ('str-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',
     CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'STORE-01','Ana Mağaza - Parçacı','İstanbul, Türkiye','0212 000 00 01',true),
    ('str-0002-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',
     CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'STORE-02','Ana Mağaza - Giyim','İstanbul, Türkiye','0212 000 00 02',true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO warehouses
(id, create_user, company_code, create_time, last_modified_time,
 warehouse_code, name, store_code, address, is_active)
VALUES
    ('whs-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',
     CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'WH-01','Ana Depo - Parçacı','STORE-01','İstanbul, Türkiye',true),
    ('whs-0002-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',
     CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'WH-02','Ana Depo - Giyim','STORE-02','İstanbul, Türkiye',true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 1. KATEGORİLER  (max 36 karakter UUID)
-- Şema: cat-XXXX-0000-0000-0000-000000000001
--        "cat-XXXX" = 8 karakter (ilk segment)
-- ================================================
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords)
VALUES
    -- Ana: Oto Yedek Parça  (level=0)
    ('cat-oto1-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Oto Yedek Parça','oto-yedek-parca','Oto yedek parça ürünleri',
     NULL,'build',1,0,'/oto-yedek-parca',
     false,'ACTIVE','{}'::jsonb,'Oto Yedek Parça','Oto parça','{oto,parça}'),

    -- Alt: Fren Sistemi  (level=1)
    ('cat-oto2-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fren Sistemi','fren-sistemi','Fren balata ve disk',
     NULL,'build',1,1,'/oto-yedek-parca/fren',
     false,'ACTIVE','{}'::jsonb,'Fren','Fren sistemi','{fren,balata}'),

    -- Alt: Filtreler  (level=1)
    ('cat-oto2-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Filtreler','filtreler','Yağ, hava, yakıt filtreleri',
     NULL,'filter_alt',2,1,'/oto-yedek-parca/filtreler',
     false,'ACTIVE','{}'::jsonb,'Filtreler','Filtre çeşitleri','{filtre,yağ}'),

    -- Alt: Elektrik & Akü  (level=1)
    ('cat-oto2-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Elektrik ve Akü','elektrik-aku','Akü ve elektrik parçaları',
     NULL,'bolt',3,1,'/oto-yedek-parca/elektrik',
     false,'ACTIVE','{}'::jsonb,'Elektrik Akü','Elektrik','{akü,buji}'),

    -- Alt: Süspansiyon  (level=1)
    ('cat-oto2-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Suspansiyon','suspansiyon','Amortisör ve rotil',
     NULL,'settings',4,1,'/oto-yedek-parca/suspansiyon',
     false,'ACTIVE','{}'::jsonb,'Suspansiyon','Suspansiyon','{amortisor}'),

    -- Ana: Giyim  (level=0)
    ('cat-elb1-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Giyim','giyim','Elbise mağazası ürünleri',
     NULL,'checkroom',2,0,'/giyim',
     false,'ACTIVE','{}'::jsonb,'Giyim','Giyim ürünleri','{giyim,moda}'),

    -- Alt: Üst Giyim  (level=1)
    ('cat-elb2-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Üst Giyim','ust-giyim','T-shirt, gömlek, sweatshirt',
     NULL,'checkroom',1,1,'/giyim/ust',
     false,'ACTIVE','{}'::jsonb,'Üst Giyim','Üst giyim','{tshirt,sweat}'),

    -- Alt: Alt Giyim  (level=1)
    ('cat-elb2-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Alt Giyim','alt-giyim','Pantolon ve etek',
     NULL,'checkroom',2,1,'/giyim/alt',
     false,'ACTIVE','{}'::jsonb,'Alt Giyim','Alt giyim','{pantolon}'),

    -- Alt: Elbise  (level=1)
    ('cat-elb2-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Elbise','elbise','Kadın elbise çeşitleri',
     NULL,'woman',3,1,'/giyim/elbise',
     false,'ACTIVE','{}'::jsonb,'Elbise','Elbise','{elbise,kadın}'),

    -- Alt: Dış Giyim  (level=1)
    ('cat-elb2-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Dis Giyim','dis-giyim','Mont ve kaban',
     NULL,'checkroom',4,1,'/giyim/dis',
     false,'ACTIVE','{}'::jsonb,'Dış Giyim','Dış giyim','{mont,kaban}')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 2. COMPANY_CATEGORIES
-- ================================================
INSERT INTO company_categories
(id, create_user, company_code, create_time, last_modified_time,
 category_id, is_active, display_order)
VALUES
    ('ccp-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto1-0000-0000-0000-000000000001',true,1),
    ('ccp-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000001',true,2),
    ('ccp-0001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000002',true,3),
    ('ccp-0001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000003',true,4),
    ('ccp-0001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-oto2-0000-0000-0000-000000000004',true,5),
    ('cce-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb1-0000-0000-0000-000000000001',true,1),
    ('cce-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000001',true,2),
    ('cce-0001-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000002',true,3),
    ('cce-0001-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000003',true,4),
    ('cce-0001-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'cat-elb2-0000-0000-0000-000000000004',true,5)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 3. MARKALAR
-- ================================================
INSERT INTO brands
(id, create_user, company_code, create_time, last_modified_time,
 name, code, description, is_active)
VALUES
    ('brd-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Bosch','BOSCH','Alman oto parça markası',true),
    ('brd-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mann Filter','MANN','Filtre uzmanı',true),
    ('brd-0001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Varta','VARTA','Akü üreticisi',true),
    ('brd-0001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Sachs','SACHS','Amortisör uzmanı',true),
    ('brd-0001-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'LC Waikiki','LCW','Türk giyim markası',true),
    ('brd-0001-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mavi','MAVI','Türk denim markası',true),
    ('brd-0001-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Koton','KOTON','Türk giyim markası',true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 4. BİRİMLER
-- ================================================
INSERT INTO units
(id, create_user, company_code, create_time, last_modified_time,
 code, name, symbol, type, is_active)
VALUES
    ('unt-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'ADET','Adet','adet','Sayılabilir',true),
    ('unt-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE', CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'TAKIM','Takım','tkm','Sayılabilir',true),
    ('unt-0002-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'ADET','Adet','adet','Sayılabilir',true),
    ('unt-0002-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'TAKIM','Takım','tkm','Sayılabilir',true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 5. TEDARİKÇİLER
-- ================================================
INSERT INTO supplier
(id, create_user, company_code, create_time, last_modified_time,
 name, contact_name, phone, email, address, notes, customer_type,
 tax_number, tax_office, credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('sup-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Otopar Yedek Parca A.S.','Ahmet Yilmaz','0212 612 00 00','info@otopar.com.tr',
     'Perpa, Istanbul','Oto parca tedarikcisi','CORPORATE',
     '1234567890','Istanbul',500000.00,30,'NORMAL',true,false),
    ('sup-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Tekstil Grup Ltd.','Fatma Demir','0212 520 00 00','satis@tekstil.com.tr',
     'Laleli, Istanbul','Giyim toptan tedarikcisi','CORPORATE',
     '9876543210','Istanbul',200000.00,45,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 5b. TEDARİKÇİ CARİ HESAPLAR
-- ================================================
INSERT INTO supplier_accounts
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, current_balance, total_debt, total_credit, overdue_amount,
 total_transaction_count, available_credit_limit, is_credit_limit_exceeded)
VALUES
    ('sac-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-0001-0000-0000-0000-000000000001', 0.00, 0.00, 0.00, 0.00, 0, 0.00, false),
    ('sac-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-0001-0000-0000-0000-000000000002', 0.00, 0.00, 0.00, 0.00, 0, 0.00, false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 6. MÜŞTERİLER
-- ================================================
INSERT INTO customer
(id, create_user, company_code, create_time, last_modified_time,
 name, phone, email, address, notes, customer_type,
 tax_number, tax_office, credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('cus-0001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Usta Oto Servis','0532 111 22 33','usta@email.com','Kadikoy, Istanbul',
     'Duzenlimüsteri','CORPORATE','1112223334','Istanbul',50000.00,30,'NORMAL',true,false),
    ('cus-0001-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Giyim Müşterisi','0533 444 55 66','giyim@email.com','Istanbul',
     'Giyim perakende müşterisi','INDIVIDUAL',NULL,NULL,5000.00,0,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 7. ÜRÜNLER
-- ================================================

-- ── 7a. PARÇACI (5 ürün) ────────────────────────
INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    ('prd-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fren Balata Seti','FRN-BLT-001','fren-balata-seti',
     'cat-oto2-0000-0000-0000-000000000001','Bosch','TAKIM',
     'On ve arka fren balata takimi',false,'ACTIVE'),

    ('prd-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Yag Filtresi','FLT-YAG-001','yag-filtresi',
     'cat-oto2-0000-0000-0000-000000000002','Mann Filter','ADET',
     'Motor yag filtresi',false,'ACTIVE'),

    ('prd-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Aku 60Ah','AKU-060-001','aku-60ah',
     'cat-oto2-0000-0000-0000-000000000003','Varta','ADET',
     'Varta Silver Dynamic 60Ah 540A',false,'ACTIVE'),

    ('prd-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'On Amortisor','SUS-AMR-001','on-amortisor',
     'cat-oto2-0000-0000-0000-000000000004','Sachs','ADET',
     'On amortisor, sol veya sag',false,'ACTIVE'),

    ('prd-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Buji Takimi 4lu','ELK-BJI-001','buji-takimi',
     'cat-oto2-0000-0000-0000-000000000003','Bosch','TAKIM',
     'Bosch iridyum buji takimi 4 adet',false,'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- ── 7b. ELBİSE MAĞAZASI (5 ürün) ───────────────
INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    ('prd-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Basic Pamuk T-Shirt','TSH-BCK-001','basic-tshirt',
     'cat-elb2-0000-0000-0000-000000000001','LC Waikiki','ADET',
     '%100 pamuk basic t-shirt',false,'ACTIVE'),

    ('prd-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Slim Fit Jean','JEN-SLM-001','slim-fit-jean',
     'cat-elb2-0000-0000-0000-000000000002','Mavi','ADET',
     'Slim fit erkek jean pantolon',false,'ACTIVE'),

    ('prd-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Yazlik Midi Elbise','ELB-MDI-001','midi-elbise',
     'cat-elb2-0000-0000-0000-000000000003','Koton','ADET',
     'Kadin yazlik midi boy elbise',false,'ACTIVE'),

    ('prd-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kapusonlu Sweatshirt','SWT-KAP-001','sweatshirt',
     'cat-elb2-0000-0000-0000-000000000001','LC Waikiki','ADET',
     'Unisex kapusonlu sweatshirt 3 iplik',false,'ACTIVE'),

    ('prd-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kis Montu','MNT-KIS-001','kis-montu',
     'cat-elb2-0000-0000-0000-000000000004','Koton','ADET',
     'Kislik sisme mont su itici',false,'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 8. ÜRÜN VARYANTLARI
-- ================================================

-- ── 8a. PARÇACI VARYANTLARI ─────────────────────
INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, product_id, is_deleted, min_stock_level, shelf_location_code, additional_price)
VALUES
    -- Fren Balata: On / Arka
    ('var-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-BLT-ON','fren-balata-on','Fren Balata - On Aks',
     'prd-oto1-0000-0000-0000-000000000001',false,5,'A-01',0.00),
    ('var-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-BLT-ARK','fren-balata-arka','Fren Balata - Arka Aks',
     'prd-oto1-0000-0000-0000-000000000001',false,5,'A-02',0.00),

    -- Yag Filtresi: Tek varyant
    ('var-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FLT-YAG-STD','yag-filtresi-std','Yag Filtresi Standart',
     'prd-oto1-0000-0000-0000-000000000002',false,10,'B-01',0.00),

    -- Aku 60Ah: Tek varyant
    ('var-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'AKU-060-STD','aku-60ah-std','Aku 60Ah Silver Dynamic',
     'prd-oto1-0000-0000-0000-000000000003',false,3,'C-01',0.00),

    -- Amortisor: Sol / Sag
    ('var-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SUS-AMR-SOL','amortisor-sol','On Amortisor Sol',
     'prd-oto1-0000-0000-0000-000000000004',false,4,'D-01',0.00),
    ('var-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SUS-AMR-SAG','amortisor-sag','On Amortisor Sag',
     'prd-oto1-0000-0000-0000-000000000004',false,4,'D-02',0.00),

    -- Buji: Tek varyant
    ('var-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ELK-BJI-STD','buji-std','Buji Takimi Iridyum 4lu',
     'prd-oto1-0000-0000-0000-000000000005',false,8,'E-01',0.00)
ON CONFLICT (id) DO NOTHING;

-- ── 8b. ELBİSE VARYANTLARI ──────────────────────
INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, product_id, is_deleted, min_stock_level, shelf_location_code, additional_price)
VALUES
    -- T-Shirt: S / M / L
    ('var-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSH-S','tshirt-s','T-Shirt S','prd-elb1-0000-0000-0000-000000000001',false,10,'F-01',0.00),
    ('var-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSH-M','tshirt-m','T-Shirt M','prd-elb1-0000-0000-0000-000000000001',false,10,'F-02',0.00),
    ('var-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSH-L','tshirt-l','T-Shirt L','prd-elb1-0000-0000-0000-000000000001',false,10,'F-03',0.00),

    -- Slim Fit Jean: 30 / 32 / 34
    ('var-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JEN-30','jean-30','Slim Fit Jean 30','prd-elb1-0000-0000-0000-000000000002',false,5,'G-01',0.00),
    ('var-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JEN-32','jean-32','Slim Fit Jean 32','prd-elb1-0000-0000-0000-000000000002',false,5,'G-02',0.00),
    ('var-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JEN-34','jean-34','Slim Fit Jean 34','prd-elb1-0000-0000-0000-000000000002',false,5,'G-03',0.00),

    -- Midi Elbise: S / M / L
    ('var-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ELB-S','elbise-s','Midi Elbise S','prd-elb1-0000-0000-0000-000000000003',false,8,'H-01',0.00),
    ('var-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ELB-M','elbise-m','Midi Elbise M','prd-elb1-0000-0000-0000-000000000003',false,8,'H-02',0.00),
    ('var-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ELB-L','elbise-l','Midi Elbise L','prd-elb1-0000-0000-0000-000000000003',false,8,'H-03',0.00),

    -- Sweatshirt: S / M / L
    ('var-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SWT-S','sweatshirt-s','Sweatshirt S','prd-elb1-0000-0000-0000-000000000004',false,10,'I-01',0.00),
    ('var-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SWT-M','sweatshirt-m','Sweatshirt M','prd-elb1-0000-0000-0000-000000000004',false,10,'I-02',0.00),
    ('var-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SWT-L','sweatshirt-l','Sweatshirt L','prd-elb1-0000-0000-0000-000000000004',false,10,'I-03',0.00),

    -- Kis Montu: S / M / L
    ('var-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'MNT-S','mont-s','Kis Montu S','prd-elb1-0000-0000-0000-000000000005',false,5,'J-01',0.00),
    ('var-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'MNT-M','mont-m','Kis Montu M','prd-elb1-0000-0000-0000-000000000005',false,5,'J-02',0.00),
    ('var-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'MNT-L','mont-l','Kis Montu L','prd-elb1-0000-0000-0000-000000000005',false,5,'J-03',0.00)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 9. BARKODLAR
-- ================================================
INSERT INTO barcodes
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, barcode_code, barcode_type, is_primary, is_active, usage_count)
VALUES
    -- Parcaci
    ('brc-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000001','8691000000001','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000002','8691000000002','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000003','8691000000003','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000004','8691000000004','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000005','8691000000005','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000006','8691000000006','EAN13',true,true,0),
    ('brc-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000007','8691000000007','EAN13',true,true,0),
    -- Elbise
    ('brc-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000001','8692000000001','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000002','8692000000002','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000003','8692000000003','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000004','8692000000004','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000005','8692000000005','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000006','8692000000006','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000007','8692000000007','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000008','8692000000008','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000009','8692000000009','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000010','8692000000010','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000011','8692000000011','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000012','8692000000012','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000013','8692000000013','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000014','8692000000014','EAN13',true,true,0),
    ('brc-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000015','8692000000015','EAN13',true,true,0)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 10. FİYATLANDIRMA
-- ================================================
INSERT INTO variant_pricing
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, purchase_price, sale_price, currency,
 vat_rate, special_tax_rate, vat_included, withholding_tax_rate, tax_exempt)
VALUES
    -- Parcaci fiyatlari
    ('vpr-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000001',180.00,320.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000002',160.00,290.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000003', 45.00, 85.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000004',1800.00,2950.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000005',650.00,1100.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000006',650.00,1100.00,'TRY',20.00,0.00,false,0.00,false),
    ('vpr-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000007',120.00,220.00,'TRY',20.00,0.00,false,0.00,false),
    -- Elbise fiyatlari
    ('vpr-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000001', 80.00,149.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000002', 80.00,149.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000003', 80.00,149.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000004',350.00,649.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000005',350.00,649.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000006',350.00,649.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000007',220.00,399.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000008',220.00,399.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000009',220.00,399.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000010',160.00,299.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000011',160.00,299.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000012',160.00,299.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000013',550.00,999.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000014',550.00,999.00,'TRY',8.00,0.00,false,0.00,false),
    ('vpr-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000015',550.00,999.00,'TRY',8.00,0.00,false,0.00,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 11. STOK HAREKETLERİ (PURCHASE_IN)
-- ================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, store_id, warehouse_id, movement_type, quantity)
VALUES
    -- Parcaci
    ('stm-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000001','STORE-01','WH-01','PURCHASE_IN',25),
    ('stm-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000002','STORE-01','WH-01','PURCHASE_IN',20),
    ('stm-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000003','STORE-01','WH-01','PURCHASE_IN',50),
    ('stm-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000004','STORE-01','WH-01','PURCHASE_IN',10),
    ('stm-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000005','STORE-01','WH-01','PURCHASE_IN',12),
    ('stm-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000006','STORE-01','WH-01','PURCHASE_IN',12),
    ('stm-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-oto1-0000-0000-0000-000000000007','STORE-01','WH-01','PURCHASE_IN',35),
    -- Elbise
    ('stm-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000001','STORE-02','WH-02','PURCHASE_IN',50),
    ('stm-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000002','STORE-02','WH-02','PURCHASE_IN',60),
    ('stm-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000003','STORE-02','WH-02','PURCHASE_IN',45),
    ('stm-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000004','STORE-02','WH-02','PURCHASE_IN',20),
    ('stm-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000005','STORE-02','WH-02','PURCHASE_IN',25),
    ('stm-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000006','STORE-02','WH-02','PURCHASE_IN',18),
    ('stm-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000007','STORE-02','WH-02','PURCHASE_IN',30),
    ('stm-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000008','STORE-02','WH-02','PURCHASE_IN',35),
    ('stm-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000009','STORE-02','WH-02','PURCHASE_IN',28),
    ('stm-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000010','STORE-02','WH-02','PURCHASE_IN',40),
    ('stm-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000011','STORE-02','WH-02','PURCHASE_IN',50),
    ('stm-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000012','STORE-02','WH-02','PURCHASE_IN',42),
    ('stm-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000013','STORE-02','WH-02','PURCHASE_IN',15),
    ('stm-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000014','STORE-02','WH-02','PURCHASE_IN',18),
    ('stm-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'var-elb1-0000-0000-0000-000000000015','STORE-02','WH-02','PURCHASE_IN',12)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 12. KULLANICILAR & ROLLER
-- ================================================
INSERT INTO role_def
(id, create_time, create_user, last_modified_time, update_user,
 company_code, code, description, is_active, is_system_role, name)
VALUES
    -- SEDCORE (Parçacı) rolleri
    ('role-admin-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','ADMIN','Tam yetkili yonetici',true,true,'Yonetici'),
    ('role-kasiy-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','CASHIER','POS satis islemleri',true,false,'Kasiyer'),
    ('role-depo0-0000-0000-0000-000000000003',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','WAREHOUSE','Stok ve depo yonetimi',true,false,'Depo Sorumlusu'),
    ('6d728059-90fb-4753-b295-953c3c5b2035','2011-05-16 15:36:38','sedat','2011-05-16 15:36:38',NULL,
     'SEDCORE','USER','user role',true,true,'sedat'),
    -- SEDCORE1 (Giyim) rolleri
    ('role-adm1-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','ADMIN','Tam yetkili yonetici',true,true,'Yonetici'),
    ('role-kas1-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','CASHIER','POS satis islemleri',true,false,'Kasiyer')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_def
(id, create_time, create_user, last_modified_time, update_user, company_code,
 generic_identifier, is_active, language_val, user_def_generic_id_type,
 user_display_name, user_name, user_type)
VALUES
    -- SEDCORE (Parçacı) kullanıcıları
    ('udef-admin-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','admin',true,'TR','AGENCY_ID','Admin Kullanici','admin','USER'),
    ('udef-kasiy-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','kasiyer',true,'TR','AGENCY_ID','Kasiyer','kasiyer','USER'),
    ('6d728059-90fb-4753-b295-953c3c5b2036','2011-05-16 15:36:38','sedat','2011-05-16 15:36:38',NULL,
     'SEDCORE','generic_identifier',true,'TR','AGENCY_ID','user display name','sedat','USER'),
    -- SEDCORE1 (Giyim) kullanıcıları
    ('udef-adm1-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','sedcore1',true,'TR','AGENCY_ID','Giyim Admin','sedcore1','USER'),
    ('udef-kas1-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','giyimkasiyer',true,'TR','AGENCY_ID','Giyim Kasiyer','giyimkasiyer','USER')
ON CONFLICT (id) DO NOTHING;

-- admin → admin123 | kasiyer → kasiyer123 | sedcore1 → sedcore1123 | giyimkasiyer → kasiyer123
INSERT INTO user_def_access
(id, create_time, create_user, last_modified_time, update_user,
 company_code, access_type, can_login, has_ip_restriction,
 ip_restriction, is_force_password_change, last_change_time,
 password_hash, salt_key, user_def_id)
VALUES
    -- SEDCORE kullanıcı erişimleri
    ('uacc-admin-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','INTERNAL',true,false,false,false,CURRENT_TIMESTAMP,
     'JI1KzWlPRvgcsVO/Y/dR7gDxxDuFlAHbxiQxj7QGjcw=','YWRtaW5zYWx0MTIzNDU2',
     'udef-admin-0000-0000-0000-000000000001'),
    ('uacc-kasiy-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','INTERNAL',true,false,false,false,CURRENT_TIMESTAMP,
     'bfV/PaJuohhVbz7cLZzThRiawQ/W4o7ohh+qdvvnvc4=','a2FzaXllcnNhbHQxMjM0',
     'udef-kasiy-0000-0000-0000-000000000002'),
    ('6d728059-90fb-4753-b295-953c3c5b2037','2011-05-16 15:36:38','sedat','2011-05-16 15:36:38',NULL,
     'SEDCORE','INTERNAL',true,true,true,true,'2011-05-16 15:36:38',
     'icerwJaNuMo0cknO9Ue/PfwtvuzD3FMs32OrjN8H8p0=','sedcore',
     '6d728059-90fb-4753-b295-953c3c5b2036'),
    -- SEDCORE1 kullanıcı erişimleri (sedcore1 → sedcore1123 | giyimkasiyer → kasiyer123)
    ('uacc-adm1-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','INTERNAL',true,false,false,false,CURRENT_TIMESTAMP,
     'JI1KzWlPRvgcsVO/Y/dR7gDxxDuFlAHbxiQxj7QGjcw=','YWRtaW5zYWx0MTIzNDU2',
     'udef-adm1-0000-0000-0000-000000000001'),
    ('uacc-kas1-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','INTERNAL',true,false,false,false,CURRENT_TIMESTAMP,
     'bfV/PaJuohhVbz7cLZzThRiawQ/W4o7ohh+qdvvnvc4=','a2FzaXllcnNhbHQxMjM0',
     'udef-kas1-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_role
(id, create_time, create_user, last_modified_time, update_user,
 company_code, role_def_id, user_def_id)
VALUES
    -- SEDCORE rolleri
    ('urol-admin-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','role-admin-0000-0000-0000-000000000001','udef-admin-0000-0000-0000-000000000001'),
    ('urol-kasiy-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE','role-kasiy-0000-0000-0000-000000000002','udef-kasiy-0000-0000-0000-000000000002'),
    ('6d728059-90fb-4753-b295-953c3c5b2038','2011-05-16 15:36:38','sedat','2011-05-16 15:36:38',NULL,
     'SEDCORE','6d728059-90fb-4753-b295-953c3c5b2035','6d728059-90fb-4753-b295-953c3c5b2036'),
    -- SEDCORE1 rolleri
    ('urol-adm1-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','role-adm1-0000-0000-0000-000000000001','udef-adm1-0000-0000-0000-000000000001'),
    ('urol-kas1-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,'SYSTEM',CURRENT_TIMESTAMP,NULL,
     'SEDCORE1','role-kas1-0000-0000-0000-000000000002','udef-kas1-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

select * from user_def_access;
