-- ================================================
-- POS Product Manager - Seed Data
-- Parçacı (5 ürün) + Elbise Mağazası (5 ürün)
-- Tüm UUID'ler max 36 karakter (varchar(36) uyumlu)
-- ================================================

-- ================================================
-- INVENTORY VIEW
-- ================================================
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
-- 11. STOK HAREKETLERİ (Tüm Tipler)
-- ================================================

-- ── 11a. SATIN ALMA GİRİŞLERİ (PURCHASE_IN) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Parcaci — İlk büyük alım
    ('stm-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','PURCHASE_IN',25),
    ('stm-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000002','STORE-01','STORE','PURCHASE_IN',20),
    ('stm-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','PURCHASE_IN',50),
    ('stm-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000004','STORE-01','STORE','PURCHASE_IN',10),
    ('stm-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000005','STORE-01','STORE','PURCHASE_IN',12),
    ('stm-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000006','STORE-01','STORE','PURCHASE_IN',12),
    ('stm-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '30 days',CURRENT_TIMESTAMP - INTERVAL '30 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','PURCHASE_IN',35),
    -- Parcaci — İkinci alım (10 gün önce)
    ('stm-oto1-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','PURCHASE_IN',15),
    ('stm-oto1-0000-0000-0000-000000000021','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','PURCHASE_IN',30),
    ('stm-oto1-0000-0000-0000-000000000022','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','PURCHASE_IN',20),
    -- Elbise
    ('stm-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','PURCHASE_IN',50),
    ('stm-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','PURCHASE_IN',60),
    ('stm-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000003','STORE-02','STORE','PURCHASE_IN',45),
    ('stm-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000004','STORE-02','STORE','PURCHASE_IN',20),
    ('stm-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000005','STORE-02','STORE','PURCHASE_IN',25),
    ('stm-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000006','STORE-02','STORE','PURCHASE_IN',18),
    ('stm-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000007','STORE-02','STORE','PURCHASE_IN',30),
    ('stm-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000008','STORE-02','STORE','PURCHASE_IN',35),
    ('stm-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000009','STORE-02','STORE','PURCHASE_IN',28),
    ('stm-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000010','STORE-02','STORE','PURCHASE_IN',40),
    ('stm-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000011','STORE-02','STORE','PURCHASE_IN',50),
    ('stm-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000012','STORE-02','STORE','PURCHASE_IN',42),
    ('stm-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000013','STORE-02','STORE','PURCHASE_IN',15),
    ('stm-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000014','STORE-02','STORE','PURCHASE_IN',18),
    ('stm-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-elb1-0000-0000-0000-000000000015','STORE-02','STORE','PURCHASE_IN',12)
ON CONFLICT (id) DO NOTHING;

-- ── 11b. SATIŞ ÇIKIŞLARI (SALE_OUT) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Parcaci — Fren Balata Ön 3 adet satış (20 gün önce)
    ('stm-oto1-0000-0000-0000-000000000030','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_OUT',3),
    -- Fren Balata Ön 2 adet satış (15 gün önce)
    ('stm-oto1-0000-0000-0000-000000000031','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_OUT',2),
    -- Fren Balata Ön 4 adet satış (5 gün önce)
    ('stm-oto1-0000-0000-0000-000000000032','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_OUT',4),
    -- Fren Balata Arka 2 adet satış
    ('stm-oto1-0000-0000-0000-000000000033','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days','var-oto1-0000-0000-0000-000000000002','STORE-01','STORE','SALE_OUT',2),
    -- Fren Balata Arka 1 adet satış
    ('stm-oto1-0000-0000-0000-000000000034','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '7 days',CURRENT_TIMESTAMP - INTERVAL '7 days','var-oto1-0000-0000-0000-000000000002','STORE-01','STORE','SALE_OUT',1),
    -- Yağ Filtresi 10 adet satış (en çok satan)
    ('stm-oto1-0000-0000-0000-000000000035','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '22 days',CURRENT_TIMESTAMP - INTERVAL '22 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','SALE_OUT',10),
    -- Yağ Filtresi 8 adet satış
    ('stm-oto1-0000-0000-0000-000000000036','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','SALE_OUT',8),
    -- Yağ Filtresi 5 adet satış
    ('stm-oto1-0000-0000-0000-000000000037','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '3 days',CURRENT_TIMESTAMP - INTERVAL '3 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','SALE_OUT',5),
    -- Akü 2 adet satış
    ('stm-oto1-0000-0000-0000-000000000038','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '14 days',CURRENT_TIMESTAMP - INTERVAL '14 days','var-oto1-0000-0000-0000-000000000004','STORE-01','STORE','SALE_OUT',2),
    -- Amortisör Sol 3 adet satış
    ('stm-oto1-0000-0000-0000-000000000039','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '16 days',CURRENT_TIMESTAMP - INTERVAL '16 days','var-oto1-0000-0000-0000-000000000005','STORE-01','STORE','SALE_OUT',3),
    -- Amortisör Sağ 3 adet satış (genelde çift satılır)
    ('stm-oto1-0000-0000-0000-000000000040','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '16 days',CURRENT_TIMESTAMP - INTERVAL '16 days','var-oto1-0000-0000-0000-000000000006','STORE-01','STORE','SALE_OUT',3),
    -- Buji Takımı 8 adet satış
    ('stm-oto1-0000-0000-0000-000000000041','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '19 days',CURRENT_TIMESTAMP - INTERVAL '19 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','SALE_OUT',8),
    -- Buji Takımı 5 adet satış
    ('stm-oto1-0000-0000-0000-000000000042','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','SALE_OUT',5),
    -- Elbise — T-Shirt S satış
    ('stm-elb1-0000-0000-0000-000000000030','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '18 days',CURRENT_TIMESTAMP - INTERVAL '18 days','var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','SALE_OUT',5),
    ('stm-elb1-0000-0000-0000-000000000031','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '10 days',CURRENT_TIMESTAMP - INTERVAL '10 days','var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','SALE_OUT',8),
    -- T-Shirt M satış
    ('stm-elb1-0000-0000-0000-000000000032','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '15 days',CURRENT_TIMESTAMP - INTERVAL '15 days','var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','SALE_OUT',12),
    -- Jean 32 satış
    ('stm-elb1-0000-0000-0000-000000000033','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '12 days',CURRENT_TIMESTAMP - INTERVAL '12 days','var-elb1-0000-0000-0000-000000000004','STORE-02','STORE','SALE_OUT',4),
    -- Elbise M satış
    ('stm-elb1-0000-0000-0000-000000000034','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '8 days',CURRENT_TIMESTAMP - INTERVAL '8 days','var-elb1-0000-0000-0000-000000000007','STORE-02','STORE','SALE_OUT',6)
ON CONFLICT (id) DO NOTHING;

-- ── 11c. SATIŞ İADELERİ (SALE_RETURN_IN) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Fren Balata Ön 1 adet iade (müşteri yanlış almış)
    ('stm-oto1-0000-0000-0000-000000000050','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '13 days',CURRENT_TIMESTAMP - INTERVAL '13 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','SALE_RETURN_IN',1),
    -- Akü 1 adet iade (arızalı)
    ('stm-oto1-0000-0000-0000-000000000051','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '11 days',CURRENT_TIMESTAMP - INTERVAL '11 days','var-oto1-0000-0000-0000-000000000004','STORE-01','STORE','SALE_RETURN_IN',1),
    -- Elbise T-Shirt M 2 adet iade (beden uymadı)
    ('stm-elb1-0000-0000-0000-000000000050','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '9 days',CURRENT_TIMESTAMP - INTERVAL '9 days','var-elb1-0000-0000-0000-000000000002','STORE-02','STORE','SALE_RETURN_IN',2)
ON CONFLICT (id) DO NOTHING;

-- ── 11d. SATIN ALMA İADELERİ (PURCHASE_RETURN_OUT) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Yağ Filtresi 5 adet tedarikçiye iade (parti hatalı)
    ('stm-oto1-0000-0000-0000-000000000060','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '25 days',CURRENT_TIMESTAMP - INTERVAL '25 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','PURCHASE_RETURN_OUT',5),
    -- Buji Takımı 3 adet tedarikçiye iade
    ('stm-oto1-0000-0000-0000-000000000061','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '20 days',CURRENT_TIMESTAMP - INTERVAL '20 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','PURCHASE_RETURN_OUT',3)
ON CONFLICT (id) DO NOTHING;

-- ── 11e. TRANSFER HAREKETLERİ (TRANSFER_OUT / TRANSFER_IN) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Fren Balata Ön: STORE-01'den SUBE-01'e 5 adet transfer
    ('stm-oto1-0000-0000-0000-000000000070','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '8 days',CURRENT_TIMESTAMP - INTERVAL '8 days','var-oto1-0000-0000-0000-000000000001','STORE-01','STORE','TRANSFER_OUT',5),
    ('stm-oto1-0000-0000-0000-000000000071','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '8 days',CURRENT_TIMESTAMP - INTERVAL '8 days','var-oto1-0000-0000-0000-000000000001','SUBE-01','STORE','TRANSFER_IN',5),
    -- Yağ Filtresi: STORE-01'den SUBE-01'e 10 adet transfer
    ('stm-oto1-0000-0000-0000-000000000072','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days','var-oto1-0000-0000-0000-000000000003','STORE-01','STORE','TRANSFER_OUT',10),
    ('stm-oto1-0000-0000-0000-000000000073','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '6 days',CURRENT_TIMESTAMP - INTERVAL '6 days','var-oto1-0000-0000-0000-000000000003','SUBE-01','STORE','TRANSFER_IN',10),
    -- Elbise T-Shirt S: STORE-02'den başka mağazaya 8 adet
    ('stm-elb1-0000-0000-0000-000000000070','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days','var-elb1-0000-0000-0000-000000000001','STORE-02','STORE','TRANSFER_OUT',8),
    ('stm-elb1-0000-0000-0000-000000000071','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '5 days',CURRENT_TIMESTAMP - INTERVAL '5 days','var-elb1-0000-0000-0000-000000000001','STORE-03','STORE','TRANSFER_IN',8)
ON CONFLICT (id) DO NOTHING;

-- ── 11f. SAYIM DÜZELTMELERİ (ADJUSTMENT_IN / ADJUSTMENT_OUT) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Amortisör Sol: sayımda 2 adet fazla çıktı
    ('stm-oto1-0000-0000-0000-000000000080','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '4 days',CURRENT_TIMESTAMP - INTERVAL '4 days','var-oto1-0000-0000-0000-000000000005','STORE-01','STORE','ADJUSTMENT_IN',2),
    -- Buji Takımı: sayımda 1 adet eksik çıktı (kayıp/hasar)
    ('stm-oto1-0000-0000-0000-000000000081','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '4 days',CURRENT_TIMESTAMP - INTERVAL '4 days','var-oto1-0000-0000-0000-000000000007','STORE-01','STORE','ADJUSTMENT_OUT',1),
    -- Elbise Jean 30: sayımda 3 adet eksik (kayıp)
    ('stm-elb1-0000-0000-0000-000000000080','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP - INTERVAL '3 days',CURRENT_TIMESTAMP - INTERVAL '3 days','var-elb1-0000-0000-0000-000000000004','STORE-02','STORE','ADJUSTMENT_OUT',3)
ON CONFLICT (id) DO NOTHING;

-- ── 11g. SATIŞ İPTALLERİ (SALE_CANCEL_IN) ────
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Amortisör Sağ: satış iptal edildi, 1 adet geri girdi
    ('stm-oto1-0000-0000-0000-000000000090','SYSTEM','SEDCORE',CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP - INTERVAL '2 days','var-oto1-0000-0000-0000-000000000006','STORE-01','STORE','SALE_CANCEL_IN',1)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- ÇOK MAĞAZA SENARYOSU: SEDCORE 2. Mağaza
-- (Kullanıcılar security modülünün data.sql'inde tanımlanır)
-- ================================================

-- SEDCORE şube mağazası (2. mağaza) — store_code global unique olduğu için SUBE-01 kullanılır
INSERT INTO stores
(id, create_user, company_code, create_time, last_modified_time,
 store_code, name, address, phone, is_active)
VALUES
    ('str-0003-0000-0000-0000-000000000001','SYSTEM','SEDCORE',
     CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SUBE-01','Şube Mağaza - Parçacı','İstanbul Anadolu, Türkiye','0216 000 00 01',true)
ON CONFLICT (id) DO NOTHING;

-- ÖNEMLİ: user_def.store_id, stock_movements.location_id (STORE tipi) ile EŞLEŞMELİDİR.
-- stock_movements location_id store_code string kullandığından user_def.store_id da store_code olmalıdır.

-- Kasiyer store_id atamaları — mağazalar oluşturulduktan sonra set edilir
-- (Kullanıcı kaydı security modülünde, store ataması burada)
UPDATE user_def SET store_id = 'STORE-01' WHERE user_name = 'kasiyer';
UPDATE user_def SET store_id = 'SUBE-01'  WHERE user_name = 'kasiyer2';
UPDATE user_def SET store_id = 'STORE-02' WHERE user_name = 'giyim_kasiyer';

-- ================================================
-- TEST VERİSİ: Çok mağaza stok senaryosu
-- ------------------------------------------------
-- Senaryo A: var-oto1-...-001 (Fren Balata Ön Aks)
--   STORE-01: 25 adet (kasiyer görür → yeşil)
--   SUBE-01:  YOK    (kasiyer2 görür → "Transferde")
--
-- Senaryo B: var-oto1-...-002 (Fren Balata Arka Aks)
--   STORE-01: 20 adet (kasiyer görür → yeşil)
--   SUBE-01:   8 adet (kasiyer2 de görür → yeşil)
--
-- Senaryo C: var-oto1-...-003 (Yağ Filtresi)
--   STORE-01: YOK (kasiyer görür → "Transferde")
--   SUBE-01:  15 adet
-- ================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, movement_type, quantity)
VALUES
    -- Senaryo B: Fren Balata Arka Aks → SUBE-01'de de stok var
    ('stm-test-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','SUBE-01','STORE','PURCHASE_IN',8),
    -- Senaryo C: Yağ Filtresi → sadece SUBE-01'de
    ('stm-test-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','SUBE-01','STORE','PURCHASE_IN',15)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 10. CROSS REFERENCES (Çapraz Referans / OEM Eşleştirme Seed Data)
-- ================================================
-- Aynı cross_ref_number'a sahip farklı varyantlar → POS'ta otomatik alternatif önerisi
-- Paylaşılan kodlar: BOSCH-0986AB1234, MANN-HU716/2X, SACHS-313472, BOSCH-F026407157, DENSO-IK20TT

-- ── 10a. PARÇACI ÇAPRAZ REFERANSLARI (SEDCORE) ──────────────
INSERT INTO cross_references
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, cross_ref_number, cross_ref_brand, notes)
VALUES
    -- ─── Fren Balata Ön Aks (var-001) ───
    -- Bosch 0986AB1234 → PAYLAŞILAN: var-001 & var-002 (Fren Balata Ön ↔ Arka eşleşir)
    ('crf-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','BOSCH-0986AB1234','Bosch','Ön aks fren balata seti - Bosch orijinal'),
    -- TRW GDB1330 → sadece var-001
    ('crf-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','TRW-GDB1330','TRW','TRW premium fren balata'),
    -- Ferodo FDB1323 → sadece var-001
    ('crf-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','FERODO-FDB1323','Ferodo','Ferodo Premier serisi'),
    -- DENSO IK20TT → PAYLAŞILAN: var-001 & var-007 (Fren Balata ↔ Buji çapraz eşleşme)
    ('crf-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','DENSO-IK20TT','Denso','Denso Iridium TT serisi'),

    -- ─── Fren Balata Arka Aks (var-002) ───
    -- Bosch 0986AB1234 → PAYLAŞILAN: var-001 & var-002
    ('crf-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','BOSCH-0986AB1234','Bosch','Arka aks fren balata seti - Bosch orijinal'),
    -- ATE 13.0460-7184 → sadece var-002
    ('crf-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','ATE-130460-7184','ATE','ATE Ceramic serisi arka balata'),
    -- Textar 2355401 → sadece var-002
    ('crf-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','TEXTAR-2355401','Textar','Textar eQ arka balata'),
    -- Brembo P85075 → sadece var-002
    ('crf-oto1-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','BREMBO-P85075','Brembo','Brembo premium arka balata'),

    -- ─── Yağ Filtresi (var-003) ───
    -- MANN HU716/2X → PAYLAŞILAN: var-003 & var-007 (Yağ Filtresi ↔ Buji bakım seti eşleşmesi)
    ('crf-oto1-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','MANN-HU716/2X','Mann-Filter','Mann yağ filtresi - VW/Audi grubu'),
    -- Bosch F026407157 → PAYLAŞILAN: var-003 & var-004 (Yağ Filtresi ↔ Akü çapraz eşleşme)
    ('crf-oto1-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','BOSCH-F026407157','Bosch','Bosch yağ filtresi P7157'),
    -- Mahle OX339/2D → sadece var-003
    ('crf-oto1-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','MAHLE-OX339/2D','Mahle','Mahle OX339 yağ filtre elemanı'),
    -- Filtron OE 688/2 → sadece var-003
    ('crf-oto1-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','FILTRON-OE688/2','Filtron','Filtron ekonomik yağ filtresi'),

    -- ─── Akü 60Ah (var-004) ───
    -- Bosch F026407157 → PAYLAŞILAN: var-003 & var-004
    ('crf-oto1-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','BOSCH-F026407157','Bosch','Bosch S4 akü serisi referans'),
    -- VARTA D59 → sadece var-004
    ('crf-oto1-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','VARTA-D59','Varta','Varta Blue Dynamic D59 60Ah'),
    -- Mutlu L3-60 → sadece var-004
    ('crf-oto1-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','MUTLU-L3-60AH','Mutlu','Mutlu SFB L3 60Ah yerli üretim'),
    -- İnci L3-060-054-013 → sadece var-004
    ('crf-oto1-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','INCI-L3-060-054','İnci','İnci Akü L3 Premium 60Ah'),

    -- ─── Amortisör Sol (var-005) ───
    -- SACHS 313472 → PAYLAŞILAN: var-005 & var-006 (Sol ↔ Sağ amortisör doğal eşleşme)
    ('crf-oto1-0000-0000-0000-000000000017','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000005','SACHS-313472','Sachs','Sachs ön sol amortisör - Golf VII'),
    -- Monroe G8010 → sadece var-005
    ('crf-oto1-0000-0000-0000-000000000018','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000005','MONROE-G8010','Monroe','Monroe OESpectrum sol amortisör'),
    -- Bilstein B4 → sadece var-005
    ('crf-oto1-0000-0000-0000-000000000019','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000005','BILSTEIN-19-105772','Bilstein','Bilstein B4 OE Replacement sol'),
    -- Kayaba KYB 339719 → PAYLAŞILAN: var-005 & var-006 (2. ortak kod)
    ('crf-oto1-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000005','KYB-339719','KYB','KYB Excel-G sol amortisör'),

    -- ─── Amortisör Sağ (var-006) ───
    -- SACHS 313472 → PAYLAŞILAN: var-005 & var-006
    ('crf-oto1-0000-0000-0000-000000000021','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000006','SACHS-313472','Sachs','Sachs ön sağ amortisör - Golf VII'),
    -- Monroe G8011 → sadece var-006
    ('crf-oto1-0000-0000-0000-000000000022','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000006','MONROE-G8011','Monroe','Monroe OESpectrum sağ amortisör'),
    -- KYB 339719 → PAYLAŞILAN: var-005 & var-006 (2. ortak kod)
    ('crf-oto1-0000-0000-0000-000000000023','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000006','KYB-339719','KYB','KYB Excel-G sağ amortisör'),
    -- Magneti Marelli → sadece var-006
    ('crf-oto1-0000-0000-0000-000000000024','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000006','MM-351834070000','Magneti Marelli','Magneti Marelli sağ amortisör'),

    -- ─── Buji Takımı (var-007) ───
    -- MANN HU716/2X → PAYLAŞILAN: var-003 & var-007
    ('crf-oto1-0000-0000-0000-000000000025','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000007','MANN-HU716/2X','Mann-Filter','Mann bakım seti referansı'),
    -- DENSO IK20TT → PAYLAŞILAN: var-001 & var-007
    ('crf-oto1-0000-0000-0000-000000000026','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000007','DENSO-IK20TT','Denso','Denso Iridium TT buji seti'),
    -- NGK BKR6EIX-11 → sadece var-007
    ('crf-oto1-0000-0000-0000-000000000027','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000007','NGK-BKR6EIX-11','NGK','NGK Iridium IX buji'),
    -- Bosch 0242235663 → sadece var-007
    ('crf-oto1-0000-0000-0000-000000000028','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000007','BOSCH-0242235663','Bosch','Bosch Double Iridium buji')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 11. PRODUCT RELATIONSHIP (Öneri Sistemi Seed Data)
-- ================================================

-- ── 10a. PARÇACI ÖNERİLERİ (SEDCORE) ──────────────
INSERT INTO product_relationship
(id, create_user, company_code, create_time, last_modified_time,
 source_product_id, target_product_id, relation_type, weight, is_active, created_by)
VALUES
    -- Fren Balata → Fren Diski (COMPLEMENTARY) - Balata değişince disk de kontrol edilir
    ('rel-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000001','prd-oto1-0000-0000-0000-000000000004','COMPLEMENTARY',9,true,'SYSTEM'),

    -- Fren Balata → Buji Takımı (COMPLEMENTARY) - Periyodik bakım seti
    ('rel-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000001','prd-oto1-0000-0000-0000-000000000005','COMPLEMENTARY',5,true,'SYSTEM'),

    -- Yağ Filtresi → Buji Takımı (COMPLEMENTARY) - Bakım sırasında birlikte değişir
    ('rel-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000002','prd-oto1-0000-0000-0000-000000000005','COMPLEMENTARY',8,true,'SYSTEM'),

    -- Yağ Filtresi → Fren Balata (COMPLEMENTARY) - Periyodik bakım
    ('rel-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000002','prd-oto1-0000-0000-0000-000000000001','COMPLEMENTARY',6,true,'SYSTEM'),

    -- Akü → Buji Takımı (COMPLEMENTARY) - Elektrik sistemi
    ('rel-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000003','prd-oto1-0000-0000-0000-000000000005','COMPLEMENTARY',7,true,'SYSTEM'),

    -- Ön Amortisör → Fren Balata (COMPLEMENTARY) - Süspansiyon bakımında fren de kontrol edilir
    ('rel-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000004','prd-oto1-0000-0000-0000-000000000001','COMPLEMENTARY',8,true,'SYSTEM'),

    -- Buji Takımı → Yağ Filtresi (COMPLEMENTARY) - Bakım seti tamamlayıcı
    ('rel-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000005','prd-oto1-0000-0000-0000-000000000002','COMPLEMENTARY',9,true,'SYSTEM'),

    -- Buji Takımı → Akü (SIMILAR) - Elektrik sistemi benzer parçalar
    ('rel-oto1-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-oto1-0000-0000-0000-000000000005','prd-oto1-0000-0000-0000-000000000003','SIMILAR',4,true,'SYSTEM')
ON CONFLICT (id) DO NOTHING;

-- ── 10b. ELBİSE MAĞAZASI ÖNERİLERİ (SEDCORE1) ────
INSERT INTO product_relationship
(id, create_user, company_code, create_time, last_modified_time,
 source_product_id, target_product_id, relation_type, weight, is_active, created_by)
VALUES
    -- T-Shirt → Jean (COMPLEMENTARY) - Üst + Alt kombin
    ('rel-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000001','prd-elb1-0000-0000-0000-000000000002','COMPLEMENTARY',9,true,'SYSTEM'),

    -- T-Shirt → Sweatshirt (ALTERNATIVE) - Aynı kategoride alternatif
    ('rel-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000001','prd-elb1-0000-0000-0000-000000000004','ALTERNATIVE',7,true,'SYSTEM'),

    -- Jean → T-Shirt (COMPLEMENTARY) - Alt + Üst kombin
    ('rel-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000002','prd-elb1-0000-0000-0000-000000000001','COMPLEMENTARY',9,true,'SYSTEM'),

    -- Jean → Sweatshirt (COMPLEMENTARY) - Alt + Üst kombin
    ('rel-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000002','prd-elb1-0000-0000-0000-000000000004','COMPLEMENTARY',8,true,'SYSTEM'),

    -- Elbise → Kış Montu (COMPLEMENTARY) - Dış giyim tamamlayıcı
    ('rel-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000003','prd-elb1-0000-0000-0000-000000000005','COMPLEMENTARY',6,true,'SYSTEM'),

    -- Sweatshirt → Jean (COMPLEMENTARY) - Üst + Alt kombin
    ('rel-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000004','prd-elb1-0000-0000-0000-000000000002','COMPLEMENTARY',9,true,'SYSTEM'),

    -- Sweatshirt → T-Shirt (SIMILAR) - Aynı kategoride benzer
    ('rel-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000004','prd-elb1-0000-0000-0000-000000000001','SIMILAR',6,true,'SYSTEM'),

    -- Kış Montu → Sweatshirt (COMPLEMENTARY) - İçine giymek için
    ('rel-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000005','prd-elb1-0000-0000-0000-000000000004','COMPLEMENTARY',8,true,'SYSTEM'),

    -- Kış Montu → Jean (COMPLEMENTARY) - Kombin
    ('rel-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000005','prd-elb1-0000-0000-0000-000000000002','COMPLEMENTARY',7,true,'SYSTEM'),

    -- Elbise → T-Shirt (ALTERNATIVE) - Alternatif üst giyim
    ('rel-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'prd-elb1-0000-0000-0000-000000000003','prd-elb1-0000-0000-0000-000000000001','ALTERNATIVE',5,true,'SYSTEM')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 12. STOCK LEVELS (Anlık Stok Bakiyeleri)
-- stock_movements üzerinden hesaplanmış net bakiyeler.
-- Yapı: (variant_id, location_id, company_code) UNIQUE
-- ================================================
-- NOT: version=0 zorunlu. @Version Long wrapper NULL kalırsa ilk UPDATE'te
--      Versioning.increment(NULL) → NullPointerException (Hibernate 6.x).
INSERT INTO stock_levels
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, location_id, location_type, quantity, min_quantity, version)
VALUES
    -- ── SEDCORE / STORE-01 ──────────────────────────────────────
    -- var-001 Fren Balata Ön Aks: IN(25+15) - OUT(3+2+4) - TRANSFER_OUT(5) + RETURN(1) = 27
    ('slv-oto1-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','STORE-01','STORE',27,5,0),
    -- var-002 Fren Balata Arka Aks: IN(20) - OUT(2+1) = 17
    ('slv-oto1-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','STORE-01','STORE',17,5,0),
    -- var-003 Yağ Filtresi: IN(50+30) - OUT(10+8+5) - PRE_RETURN(5) - TRANSFER_OUT(10) = 42
    ('slv-oto1-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','STORE-01','STORE',42,10,0),
    -- var-004 Akü: IN(10) - OUT(2) + RETURN(1) = 9
    ('slv-oto1-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000004','STORE-01','STORE',9,2,0),
    -- var-005 Amortisör Sol: IN(12) - OUT(3) + ADJ_IN(2) = 11
    ('slv-oto1-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000005','STORE-01','STORE',11,4,0),
    -- var-006 Amortisör Sağ: IN(12) - OUT(3) + CANCEL_IN(1) = 10
    ('slv-oto1-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000006','STORE-01','STORE',10,4,0),
    -- var-007 Buji Takımı: IN(35+20) - OUT(8+5) - PRE_RETURN(3) - ADJ_OUT(1) = 38
    ('slv-oto1-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000007','STORE-01','STORE',38,8,0),

    -- ── SEDCORE / SUBE-01 ────────────────────────────────────────
    -- var-001 Fren Balata Ön Aks: TRANSFER_IN(5) = 5
    ('slv-oto1-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000001','SUBE-01','STORE',5,5,0),
    -- var-002 Fren Balata Arka Aks: PURCHASE_IN(8) = 8
    ('slv-oto1-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000002','SUBE-01','STORE',8,5,0),
    -- var-003 Yağ Filtresi: PURCHASE_IN(15) + TRANSFER_IN(10) = 25
    ('slv-oto1-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-oto1-0000-0000-0000-000000000003','SUBE-01','STORE',25,10,0),

    -- ── SEDCORE1 / STORE-02 ──────────────────────────────────────
    -- var-elb-001 T-Shirt S: IN(50) - OUT(5+8) - TRANSFER_OUT(8) = 29
    ('slv-elb1-0000-0000-0000-000000000001','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000001','STORE-02','STORE',29,10,0),
    -- var-elb-002 T-Shirt M: IN(60) - OUT(12) + RETURN(2) = 50
    ('slv-elb1-0000-0000-0000-000000000002','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000002','STORE-02','STORE',50,10,0),
    -- var-elb-003 T-Shirt L: IN(45) = 45
    ('slv-elb1-0000-0000-0000-000000000003','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000003','STORE-02','STORE',45,10,0),
    -- var-elb-004 Jean 32: IN(20) - OUT(4) - ADJ_OUT(3) = 13
    ('slv-elb1-0000-0000-0000-000000000004','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000004','STORE-02','STORE',13,5,0),
    -- var-elb-005..015: doğrudan PURCHASE_IN miktarları (hareket yok)
    ('slv-elb1-0000-0000-0000-000000000005','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000005','STORE-02','STORE',25,5,0),
    ('slv-elb1-0000-0000-0000-000000000006','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000006','STORE-02','STORE',18,5,0),
    -- var-elb-007 Elbise M: IN(30) - OUT(6) = 24
    ('slv-elb1-0000-0000-0000-000000000007','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000007','STORE-02','STORE',24,5,0),
    ('slv-elb1-0000-0000-0000-000000000008','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000008','STORE-02','STORE',35,5,0),
    ('slv-elb1-0000-0000-0000-000000000009','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000009','STORE-02','STORE',28,5,0),
    ('slv-elb1-0000-0000-0000-000000000010','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000010','STORE-02','STORE',40,5,0),
    ('slv-elb1-0000-0000-0000-000000000011','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000011','STORE-02','STORE',50,5,0),
    ('slv-elb1-0000-0000-0000-000000000012','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000012','STORE-02','STORE',42,5,0),
    ('slv-elb1-0000-0000-0000-000000000013','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000013','STORE-02','STORE',15,5,0),
    ('slv-elb1-0000-0000-0000-000000000014','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000014','STORE-02','STORE',18,5,0),
    ('slv-elb1-0000-0000-0000-000000000015','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000015','STORE-02','STORE',12,5,0),

    -- ── SEDCORE1 / STORE-03 (Transfer gelen) ─────────────────────
    -- var-elb-001 T-Shirt S: TRANSFER_IN(8) = 8
    ('slv-elb1-0000-0000-0000-000000000020','SYSTEM','SEDCORE1',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-elb1-0000-0000-0000-000000000001','STORE-03','STORE',8,5,0)
ON CONFLICT (id) DO NOTHING;

select * from user_def_access;

-- ── supplier_claims ─────────────────────────────────────────────────────────
-- Tablo Hibernate tarafından yönetilir (ddl-auto=create).
-- Seed veri yok — claim'ler createPurchase() veya resolveClaim() ile oluşturulur.
-- Yeni alanlar (Purchase): invoice_amount, discount_amount, shortage_amount, purchase_status
-- Yeni enum'lar: PurchaseStatus, ClaimReason, ClaimStatus
