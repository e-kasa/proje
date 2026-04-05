-- ================================================
-- POS Product Manager - Seed Data
-- ================================================

-- ================================================
-- INVENTORY VIEW
-- Stok hareketlerini (stock_movements) toplayarak
-- varyant + depo + mağaza bazında anlık stoku hesaplar.
-- physicalQuantity = SUM(IN hareketler) - SUM(OUT hareketler)
-- JPA @Immutable entity olduğu için manuel oluşturulur.
-- ================================================
DROP TABLE IF EXISTS inventory_view;
DROP VIEW IF EXISTS inventory_view;
CREATE VIEW inventory_view AS
SELECT
    -- TOpenSimpleCompanyEntity kolonları (Hibernate için zorunlu)
    gen_random_uuid()::text                              AS id,
    sm.company_code,
    'SYSTEM'::varchar                                    AS create_user,
    CURRENT_TIMESTAMP                                    AS create_time,
    CURRENT_TIMESTAMP                                    AS last_modified_time,
    NULL::varchar                                        AS update_user,
    -- Stok alanları
    sm.variant_id,
    sm.store_id,
    sm.warehouse_id,
    SUM(
        CASE
            WHEN sm.movement_type IN (
                'PURCHASE_IN', 'SALE_RETURN_IN',
                'TRANSFER_IN', 'ADJUSTMENT_IN'
            ) THEN sm.quantity
            ELSE 0
        END
    ) -
    SUM(
        CASE
            WHEN sm.movement_type IN (
                'SALE_OUT', 'PURCHASE_RETURN_OUT',
                'TRANSFER_OUT', 'ADJUSTMENT_OUT'
            ) THEN sm.quantity
            ELSE 0
        END
    )                                                    AS physical_quantity
FROM stock_movements sm
GROUP BY
    sm.company_code,
    sm.variant_id,
    sm.store_id,
    sm.warehouse_id;

-- ================================================
-- 0. STORES & WAREHOUSES
-- storeId / warehouseId alanları StockMovement'ta plain String.
-- code alanı bu String değerlerle eşleşir.
-- ================================================

INSERT INTO stores
(id, create_user, company_code, create_time, last_modified_time,
 store_code, name, address, phone, is_active)
VALUES
    ('str-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'STORE-01','Ana Mağaza','İstanbul, Türkiye','0212 000 00 01',true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO warehouses
(id, create_user, company_code, create_time, last_modified_time,
 warehouse_code, name, store_code, address, is_active)
VALUES
    ('whs-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'WH-01','Ana Depo','STORE-01','İstanbul, Türkiye',true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 1. CATEGORIES  (TOpenSimpleDbEntity → company_code YOK)
-- ================================================

-- 1a. Ana Kategoriler (level = 0, parent_id = NULL)
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords)
VALUES
    ('cat-0001-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Elektronik','elektronik','Elektronik urunler',NULL,'laptop',1,0,'/elektronik',
     false,'ACTIVE','{}'::jsonb,'Elektronik','Elektronik urunler','elektronik,teknoloji'),

    ('cat-0001-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Giyim ve Aksesuar','giyim-aksesuar','Giyim ve aksesuar urunleri',NULL,'shirt',2,0,'/giyim-aksesuar',
     false,'ACTIVE','{}'::jsonb,'Giyim Aksesuar','Giyim ve aksesuar kategorisi','giyim,aksesuar,moda'),

    ('cat-0001-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Gida ve Icecek','gida-icecek','Gida ve icecek urunleri',NULL,'basket',3,0,'/gida-icecek',
     false,'ACTIVE','{}'::jsonb,'Gida Icecek','Gida ve icecek urunleri','gida,icecek,market'),

    ('cat-0001-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kisisel Bakim ve Kozmetik','kisisel-bakim','Kisisel bakim ve kozmetik urunleri',NULL,'heart',4,0,'/kisisel-bakim',
     false,'ACTIVE','{}'::jsonb,'Kisisel Bakim','Kisisel bakim ve kozmetik','kozmetik,bakim,guzellik'),

    ('cat-0001-0000-0000-0000-000000000005','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kirtasiye ve Ofis','kirtasiye-ofis','Kirtasiye ve ofis malzemeleri',NULL,'book',5,0,'/kirtasiye-ofis',
     false,'ACTIVE','{}'::jsonb,'Kirtasiye Ofis','Kirtasiye ve ofis malzemeleri','kirtasiye,ofis,okul'),

    ('cat-0001-0000-0000-0000-000000000006','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Ev ve Yasam','ev-yasam','Ev ve yasam urunleri',NULL,'home',6,0,'/ev-yasam',
     false,'ACTIVE','{}'::jsonb,'Ev Yasam','Ev ve yasam urunleri','ev,yasam,dekorasyon'),

    ('cat-0001-0000-0000-0000-000000000007','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Spor ve Outdoor','spor-outdoor','Spor ve outdoor urunleri',NULL,'dumbbell',7,0,'/spor-outdoor',
     false,'ACTIVE','{}'::jsonb,'Spor Outdoor','Spor ve outdoor urunleri','spor,outdoor,fitness'),

    ('cat-0001-0000-0000-0000-000000000008','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Oyuncak ve Hobi','oyuncak-hobi','Oyuncak ve hobi urunleri',NULL,'puzzle',8,0,'/oyuncak-hobi',
     false,'ACTIVE','{}'::jsonb,'Oyuncak Hobi','Oyuncak ve hobi urunleri','oyuncak,hobi,egitim')
ON CONFLICT (id) DO NOTHING;

-- 1b. Alt Kategoriler (level = 1)
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords, parent_id)
VALUES
    ('cat-0002-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Telefon ve Tablet','telefon-tablet','Telefon ve tablet urunleri',NULL,'phone',1,1,'/elektronik/telefon-tablet',
     false,'ACTIVE','{}'::jsonb,'Telefon Tablet','Telefon ve tablet urunleri','telefon,tablet,smartphone',
     'cat-0001-0000-0000-0000-000000000001'),

    ('cat-0002-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Bilgisayar ve Laptop','bilgisayar-laptop','Bilgisayar ve laptop urunleri',NULL,'laptop',2,1,'/elektronik/bilgisayar',
     false,'ACTIVE','{}'::jsonb,'Bilgisayar Laptop','Bilgisayar ve laptop urunleri','bilgisayar,laptop,notebook',
     'cat-0001-0000-0000-0000-000000000001'),

    ('cat-0002-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TV ve Goruntu Sistemleri','tv-goruntu','TV ve goruntu sistemleri',NULL,'tv',3,1,'/elektronik/tv-goruntu',
     false,'ACTIVE','{}'::jsonb,'TV Goruntu','TV ve goruntu sistemleri','tv,televizyon,monitor',
     'cat-0001-0000-0000-0000-000000000001'),

    ('cat-0002-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Elektronik Aksesuar','elektronik-aksesuar','Kablo, adaptor ve aksesuar',NULL,'plug',4,1,'/elektronik/aksesuar',
     false,'ACTIVE','{}'::jsonb,'Elektronik Aksesuar','Elektronik aksesuar urunleri','aksesuar,kablo,sarj',
     'cat-0001-0000-0000-0000-000000000001'),

    ('cat-0002-0000-0000-0000-000000000005','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Erkek Giyim','erkek-giyim','Erkek giyim koleksiyonu',NULL,'shirt',1,1,'/giyim-aksesuar/erkek',
     false,'ACTIVE','{}'::jsonb,'Erkek Giyim','Erkek giyim koleksiyonu','erkek,giyim,kiyafet',
     'cat-0001-0000-0000-0000-000000000002'),

    ('cat-0002-0000-0000-0000-000000000006','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kadin Giyim','kadin-giyim','Kadin giyim koleksiyonu',NULL,'dress',2,1,'/giyim-aksesuar/kadin',
     false,'ACTIVE','{}'::jsonb,'Kadin Giyim','Kadin giyim koleksiyonu','kadin,giyim,kiyafet',
     'cat-0001-0000-0000-0000-000000000002'),

    ('cat-0002-0000-0000-0000-000000000007','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Cocuk Giyim','cocuk-giyim','Cocuk giyim koleksiyonu',NULL,'baby',3,1,'/giyim-aksesuar/cocuk',
     false,'ACTIVE','{}'::jsonb,'Cocuk Giyim','Cocuk giyim koleksiyonu','cocuk,bebek,giyim',
     'cat-0001-0000-0000-0000-000000000002'),

    ('cat-0002-0000-0000-0000-000000000008','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Ayakkabi','ayakkabi','Erkek kadin ve cocuk ayakkabilari',NULL,'shoe',4,1,'/giyim-aksesuar/ayakkabi',
     false,'ACTIVE','{}'::jsonb,'Ayakkabi','Ayakkabi koleksiyonu','ayakkabi,bot,sandalet',
     'cat-0001-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

-- 1c. Alt-Alt Kategoriler (level = 2, parent_id → level-1 kategoriler)
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords, parent_id)
VALUES
    -- ── Telefon ve Tablet altı ──────────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Akilli Telefon','akilli-telefon','Akilli telefon urunleri',NULL,'phone',1,2,
     '/elektronik/telefon-tablet/akilli-telefon',
     false,'ACTIVE','{}'::jsonb,'Akilli Telefon','Akilli telefon urunleri','telefon,akilli,smartphone',
     'cat-0002-0000-0000-0000-000000000001'),

    ('cat-0003-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Tablet','tablet','Tablet urunleri',NULL,'tablet',2,2,
     '/elektronik/telefon-tablet/tablet',
     false,'ACTIVE','{}'::jsonb,'Tablet','Tablet urunleri','tablet,ipad,android',
     'cat-0002-0000-0000-0000-000000000001'),

    -- ── Bilgisayar ve Laptop altı ───────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Laptop','laptop','Laptop urunleri',NULL,'laptop',1,2,
     '/elektronik/bilgisayar/laptop',
     false,'ACTIVE','{}'::jsonb,'Laptop','Laptop ve notebook urunleri','laptop,notebook,ultrabook',
     'cat-0002-0000-0000-0000-000000000002'),

    ('cat-0003-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Masaustu Bilgisayar','masaustu-bilgisayar','Masaustu bilgisayar urunleri',NULL,'desktop',2,2,
     '/elektronik/bilgisayar/masaustu',
     false,'ACTIVE','{}'::jsonb,'Masaustu Bilgisayar','Masaustu bilgisayar urunleri','masaustu,pc,desktop',
     'cat-0002-0000-0000-0000-000000000002'),

    -- ── TV ve Görüntü Sistemleri altı ──────────────────────────────
    ('cat-0003-0000-0000-0000-000000000005','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Televizyon','televizyon','LED ve OLED televizyonlar',NULL,'tv',1,2,
     '/elektronik/tv-goruntu/televizyon',
     false,'ACTIVE','{}'::jsonb,'Televizyon','LED OLED Smart TV urunleri','tv,televizyon,smart-tv',
     'cat-0002-0000-0000-0000-000000000003'),

    ('cat-0003-0000-0000-0000-000000000006','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Monitorler','monitorler','Bilgisayar monitorleri',NULL,'monitor',2,2,
     '/elektronik/tv-goruntu/monitorler',
     false,'ACTIVE','{}'::jsonb,'Monitor','Bilgisayar monitor urunleri','monitor,ekran,display',
     'cat-0002-0000-0000-0000-000000000003'),

    -- ── Erkek Giyim altı ───────────────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000007','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Erkek Tisort ve Gomlek','erkek-tisort-gomlek','Erkek tisort ve gomlek koleksiyonu',NULL,'shirt',1,2,
     '/giyim-aksesuar/erkek/tisort-gomlek',
     false,'ACTIVE','{}'::jsonb,'Erkek Tisort Gomlek','Erkek tisort ve gomlek','erkek,tisort,gomlek',
     'cat-0002-0000-0000-0000-000000000005'),

    ('cat-0003-0000-0000-0000-000000000008','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Erkek Pantolon ve Kot','erkek-pantolon-kot','Erkek pantolon ve kot koleksiyonu',NULL,'jeans',2,2,
     '/giyim-aksesuar/erkek/pantolon-kot',
     false,'ACTIVE','{}'::jsonb,'Erkek Pantolon Kot','Erkek pantolon ve kot','erkek,pantolon,kot,jean',
     'cat-0002-0000-0000-0000-000000000005'),

    -- ── Kadın Giyim altı ───────────────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000009','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kadin Elbise ve Etek','kadin-elbise-etek','Kadin elbise ve etek koleksiyonu',NULL,'dress',1,2,
     '/giyim-aksesuar/kadin/elbise-etek',
     false,'ACTIVE','{}'::jsonb,'Kadin Elbise Etek','Kadin elbise ve etek koleksiyonu','kadin,elbise,etek',
     'cat-0002-0000-0000-0000-000000000006'),

    ('cat-0003-0000-0000-0000-000000000010','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kadin Bluz ve Gomlek','kadin-bluz-gomlek','Kadin bluz ve gomlek koleksiyonu',NULL,'blouse',2,2,
     '/giyim-aksesuar/kadin/bluz-gomlek',
     false,'ACTIVE','{}'::jsonb,'Kadin Bluz Gomlek','Kadin bluz ve gomlek koleksiyonu','kadin,bluz,gomlek',
     'cat-0002-0000-0000-0000-000000000006'),

    -- ── Çocuk Giyim altı ───────────────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000011','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Bebek Giyim','bebek-giyim','0-2 yas bebek giyim koleksiyonu',NULL,'baby',1,2,
     '/giyim-aksesuar/cocuk/bebek',
     false,'ACTIVE','{}'::jsonb,'Bebek Giyim','Bebek giyim koleksiyonu','bebek,0-2-yas,tulum',
     'cat-0002-0000-0000-0000-000000000007'),

    ('cat-0003-0000-0000-0000-000000000012','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Cocuk Tisort ve Pantolon','cocuk-tisort-pantolon','2-14 yas cocuk giyim koleksiyonu',NULL,'child',2,2,
     '/giyim-aksesuar/cocuk/tisort-pantolon',
     false,'ACTIVE','{}'::jsonb,'Cocuk Tisort Pantolon','Cocuk giyim koleksiyonu','cocuk,tisort,pantolon',
     'cat-0002-0000-0000-0000-000000000007'),

    -- ── Ayakkabı altı ──────────────────────────────────────────────
    ('cat-0003-0000-0000-0000-000000000013','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Spor Ayakkabi','spor-ayakkabi','Spor ve gunluk ayakkabi koleksiyonu',NULL,'sneaker',1,2,
     '/giyim-aksesuar/ayakkabi/spor',
     false,'ACTIVE','{}'::jsonb,'Spor Ayakkabi','Spor ayakkabi koleksiyonu','spor,ayakkabi,sneaker',
     'cat-0002-0000-0000-0000-000000000008'),

    ('cat-0003-0000-0000-0000-000000000014','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Klasik Ayakkabi','klasik-ayakkabi','Klasik ve resmi ayakkabi koleksiyonu',NULL,'shoe',2,2,
     '/giyim-aksesuar/ayakkabi/klasik',
     false,'ACTIVE','{}'::jsonb,'Klasik Ayakkabi','Klasik ve resmi ayakkabi','klasik,ayakkabi,resmi,formal',
     'cat-0002-0000-0000-0000-000000000008')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 2. CATEGORY_ATTRIBUTES  (TOpenSimpleDbEntity)
-- ================================================
INSERT INTO category_attributes
(id, create_time, last_modified_time, create_user, update_user,
 category_id, attribute_key, attribute_name, attribute_name_en, attribute_type,
 is_required, is_filterable, is_active)
VALUES
    ('attr-0001-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000001','brand','Marka','Brand','TEXT',false,true,true),

    ('attr-0001-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0002-0000-0000-0000-000000000001','storage','Depolama','Storage','SELECT',false,true,true),

    ('attr-0001-0000-0000-0000-000000000003',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0002-0000-0000-0000-000000000001','ram','RAM','RAM','SELECT',false,true,true),

    ('attr-0001-0000-0000-0000-000000000004',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0002-0000-0000-0000-000000000002','screen_size','Ekran Boyutu','Screen Size','NUMBER',false,true,true),

    ('attr-0001-0000-0000-0000-000000000005',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000002','gender','Cinsiyet','Gender','SELECT',false,true,true),

    ('attr-0001-0000-0000-0000-000000000006',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000002','material','Materyal','Material','TEXT',false,true,true)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 3. CATEGORY_VARIANTS  (TOpenSimpleDbEntity)
-- ================================================
INSERT INTO category_variants
(id, create_time, last_modified_time, create_user, update_user,
 category_id, variant_key, variant_name, variant_name_en, variant_type,
 is_required, is_active, display_order, options)
VALUES
    ('var-0001-0000-0000-0000-000000000001',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000001','color','Renk','Color','COLOR',
     false,true,1,'["Siyah","Beyaz","Gumus","Mavi","Kirmizi"]'::jsonb),

    ('var-0001-0000-0000-0000-000000000002',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0002-0000-0000-0000-000000000001','storage','Depolama','Storage','SELECT',
     false,true,2,'["64 GB","128 GB","256 GB","512 GB"]'::jsonb),

    ('var-0001-0000-0000-0000-000000000003',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000002','size','Beden','Size','SELECT',
     true,true,1,'["XS","S","M","L","XL","XXL"]'::jsonb),

    ('var-0001-0000-0000-0000-000000000004',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0001-0000-0000-0000-000000000002','color','Renk','Color','COLOR',
     false,true,2,'["Beyaz","Siyah","Lacivert","Kirmizi","Yesil","Gri"]'::jsonb),

    ('var-0001-0000-0000-0000-000000000005',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SYSTEM',NULL,
     'cat-0002-0000-0000-0000-000000000008','shoe_size','Numara','Size','SELECT',
     true,true,1,'["36","37","38","39","40","41","42","43","44","45"]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 4. COMPANY_CATEGORIES  (TOpenSimpleCompanyEntity - company_code VAR)
--    Firmanin kullandigi kategoriler
-- ================================================
INSERT INTO company_categories
(id, create_user, company_code, create_time, last_modified_time,
 category_id, is_active, display_order)
VALUES
    ('cc-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000001',true,1),
    ('cc-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000002',true,2),
    ('cc-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000003',true,3),
    ('cc-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000004',true,4),
    ('cc-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000005',true,5),
    ('cc-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000006',true,6),
    ('cc-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000007',true,7),
    ('cc-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0001-0000-0000-0000-000000000008',true,8),
    ('cc-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0002-0000-0000-0000-000000000001',true,9),
    ('cc-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0002-0000-0000-0000-000000000002',true,10),
    ('cc-00001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0002-0000-0000-0000-000000000005',true,11),
    ('cc-00001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0002-0000-0000-0000-000000000006',true,12),
    -- Level-2 (torun) kategoriler — SEDCORE firması bunları da kullanıyor
    ('cc-00001-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000001',true,13),  -- Akilli Telefon
    ('cc-00001-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000002',true,14),  -- Tablet
    ('cc-00001-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000003',true,15),  -- Laptop
    ('cc-00001-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000004',true,16),  -- Masaustu Bilgisayar
    ('cc-00001-0000-0000-0000-000000000017','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000007',true,17),  -- Erkek Tisort ve Gomlek
    ('cc-00001-0000-0000-0000-000000000018','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000008',true,18),  -- Erkek Pantolon ve Kot
    ('cc-00001-0000-0000-0000-000000000019','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000009',true,19),  -- Kadin Elbise ve Etek
    ('cc-00001-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cat-0003-0000-0000-0000-000000000013',true,20)   -- Spor Ayakkabi
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 5. SUPPLIERS  (TOpenSimpleCompanyEntity)
-- website: tedarikçinin sipariş / katalog sitesi (satın alma ekranında
--          "Ürünleri Gör" butonu için kullanılır)
-- ================================================
INSERT INTO supplier
(id, create_user, company_code, create_time, last_modified_time,
 name, contact_name, phone, email, address, notes, website,
 customer_type, tax_number, tax_office, credit_limit, payment_term_days,
 risk_status, is_active, is_deleted)
VALUES
    -- TechMobil — telefon, laptop, elektronik aksesuar
    ('sup-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TechMobil A.S.','Mehmet Demir','+90 212 444 0101','info@techmobil.com.tr','Ikitelli OSB, Istanbul',
     'Telefon, laptop ve elektronik aksesuar tedarikçisi',
     'https://www.techmobil.com.tr/urunler',
     'CORPORATE','1234567890','Bagcilar VD',100000.00,30,'NORMAL',true,false),

    -- Tekstil Grup — t-shirt, gömlek, pantolon, outdoor giyim
    ('sup-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Tekstil Grup Ltd. Sti.','Ayse Kaya','+90 332 555 0202','satis@tekstilgrup.com','Karatay OSB, Konya',
     'Erkek, kadin ve cocuk giyim urun tedarikçisi',
     'https://www.tekstilgrup.com/b2b-katalog',
     'CORPORATE','9876543210','Karatay VD',50000.00,45,'NORMAL',true,false),

    -- Genel Dagitim — kalem, kirtasiye, ev esyasi, aksesuarlar
    ('sup-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Genel Dagitim Ticaret','Hasan Yilmaz','+90 216 333 0303','info@geneldagitim.com','Umraniye, Istanbul',
     'Kirtasiye, ev esyasi ve genel tuketim mallari',
     'https://www.geneldagitim.com/toptan',
     'CORPORATE','1122334455','Umraniye VD',30000.00,30,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 5b. SUPPLIER_ACCOUNTS (Tedarikci cari hesaplari)
-- ================================================
INSERT INTO supplier_accounts
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, current_balance, total_debt, total_credit, overdue_amount,
 total_transaction_count, last_transaction_date, last_payment_date, last_purchase_date,
 available_credit_limit, is_credit_limit_exceeded)
VALUES
    -- TechMobil A.S. (limit: 100,000 TL) — aktif borç var, limit dahilinde
    ('sac-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000001',
     45000.00, 60000.00, 15000.00, 8000.00,
     5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
     55000.00, false),

    -- Tekstil Grup Ltd. (limit: 50,000 TL) — limit asilmis
    ('sac-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000002',
     52000.00, 52000.00, 0.00, 12000.00,
     3, CURRENT_TIMESTAMP, NULL, CURRENT_TIMESTAMP,
     -2000.00, true),

    -- Genel Dagitim (limit: 30,000 TL) — temiz hesap, odeme yapilmis
    ('sac-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000003',
     12000.00, 20000.00, 8000.00, 0.00,
     2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
     18000.00, false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 6. CUSTOMERS  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO customer
(id, create_user, company_code, create_time, last_modified_time,
 name, phone, email, address, notes,
 customer_type, tax_number, tax_office, bank_name,
 credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('cus-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Ali Yilmaz','+90 555 111 2233','ali.yilmaz@email.com','Kadikoy, Istanbul',NULL,
     'INDIVIDUAL',NULL,NULL,NULL,
     5000.00,30,'NORMAL',true,false),

    ('cus-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Karadeniz Elektronik Ltd. Sti.','+90 212 600 4455','satin@karadenizele.com','Bagcilar, Istanbul',NULL,
     'CORPORATE','5544332211','Bagcilar VD','Ziraat Bankasi',
     50000.00,60,'NORMAL',true,false),

    ('cus-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fatma Kaya','+90 532 222 3344','fatma.kaya@email.com','Cankaya, Ankara',NULL,
     'INDIVIDUAL',NULL,NULL,NULL,
     2000.00,30,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 7. PRODUCTS  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    -- category_id = level-2 (torun): Samsung A54 → Akilli Telefon
    ('prd-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Samsung Galaxy A54 5G','PRD-SAM-A54','samsung-galaxy-a54',
     'cat-0003-0000-0000-0000-000000000001','Samsung','ADET',
     'Samsung Galaxy A54 5G akilli telefon',false,'ACTIVE'),

    -- category_id = level-2 (torun): MacBook → Laptop
    ('prd-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Apple MacBook Air M2','PRD-APPLE-MBA-M2','apple-macbook-air-m2',
     'cat-0003-0000-0000-0000-000000000003','Apple','ADET',
     'Apple MacBook Air M2 cipli dizustu bilgisayar',false,'ACTIVE'),

    -- category_id = level-2 (torun): Basic T-Shirt → Erkek Tisort ve Gomlek
    ('prd-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Pamuklu Basic T-Shirt','PRD-TSHIRT-BASIC','pamuklu-basic-tshirt',
     'cat-0003-0000-0000-0000-000000000007','Marka Tekstil','ADET',
     '%100 pamuk basic t-shirt erkek',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Pilot G2 Jel Kalem','PRD-PILOT-G2','pilot-g2-jel-kalem',
     'cat-0001-0000-0000-0000-000000000005','Pilot','ADET',
     'Pilot G2 0.7 uc jel kalem',false,'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 8. PRODUCT_VARIANTS  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, additional_price, attributes, product_id, is_deleted)
VALUES
    ('pvr-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAM-A54-BLK-128','sam-a54-siyah-128','Samsung Galaxy A54 Siyah 128GB',
     0.00,'{"color":"Siyah","storage":"128 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000001',false),

    ('pvr-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAM-A54-WHT-128','sam-a54-beyaz-128','Samsung Galaxy A54 Beyaz 128GB',
     0.00,'{"color":"Beyaz","storage":"128 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000001',false),

    ('pvr-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAM-A54-BLK-256','sam-a54-siyah-256','Samsung Galaxy A54 Siyah 256GB',
     1500.00,'{"color":"Siyah","storage":"256 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000001',false),

    ('pvr-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'APPLE-MBA-M2-MNT-256','apple-mba-m2-gece-256','MacBook Air M2 Gece Yarisi 256GB',
     0.00,'{"color":"Gece Yarisi","storage":"256 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000002',false),

    ('pvr-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'APPLE-MBA-M2-SL-512','apple-mba-m2-yildiz-512','MacBook Air M2 Yildiz Isigi 512GB',
     10000.00,'{"color":"Yildiz Isigi","storage":"512 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000002',false),

    ('pvr-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSHIRT-NAVY-M','tshirt-lacivert-m','Pamuklu Basic T-Shirt Lacivert M',
     0.00,'{"color":"Lacivert","size":"M"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000003',false),

    ('pvr-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSHIRT-NAVY-L','tshirt-lacivert-l','Pamuklu Basic T-Shirt Lacivert L',
     0.00,'{"color":"Lacivert","size":"L"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000003',false),

    ('pvr-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'TSHIRT-WHT-M','tshirt-beyaz-m','Pamuklu Basic T-Shirt Beyaz M',
     0.00,'{"color":"Beyaz","size":"M"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000003',false),

    ('pvr-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'PILOT-G2-BLUE','pilot-g2-mavi','Pilot G2 Jel Kalem Mavi',
     0.00,'{"color":"Mavi"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000004',false),

    ('pvr-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'PILOT-G2-BLACK','pilot-g2-siyah','Pilot G2 Jel Kalem Siyah',
     0.00,'{"color":"Siyah"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000004',false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 7b. EK ÜRÜNLER  (her tedarikçinin kataloğundan örnekler)
-- TechMobil (sup-001) → Elektronik
-- Tekstil Grup (sup-002) → Giyim
-- Genel Dagitim (sup-003) → Kirtasiye / Ev
-- ================================================

INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    -- TechMobil ürünleri (level-2 kategoriler)
    ('prd-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Samsung Galaxy A35 5G','PRD-SAM-A35','samsung-galaxy-a35',
     'cat-0003-0000-0000-0000-000000000001','Samsung','ADET',
     'Samsung Galaxy A35 5G akilli telefon',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JBL Tune 770NC Kulaklik','PRD-JBL-T770','jbl-tune-770nc',
     'cat-0002-0000-0000-0000-000000000004','JBL','ADET',
     'JBL Tune 770NC aktif gurultu onleyici kulaklik',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Anker 65W GaN Sarj Adaptoru','PRD-ANKER-65W','anker-65w-gan',
     'cat-0002-0000-0000-0000-000000000004','Anker','ADET',
     'Anker Nano II 65W GaN USB-C sarj adaptoru',false,'ACTIVE'),

    -- Tekstil Grup ürünleri (level-2 kategoriler)
    ('prd-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Slim Fit Oxford Gomlek','PRD-OXFORD-SLM','slim-fit-oxford-gomlek',
     'cat-0003-0000-0000-0000-000000000007','Marka Tekstil','ADET',
     'Erkek slim fit pamuklu Oxford gomlek',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Jogger Esofman Alti','PRD-JOGGER-01','jogger-esofman-alti',
     'cat-0003-0000-0000-0000-000000000008','Marka Tekstil','ADET',
     'Erkek pamuklu jogger esofman alti',false,'ACTIVE'),

    -- Genel Dagitim ürünleri
    ('prd-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Stabilo Boss Highlighter Seti','PRD-STABILO-BOSS','stabilo-boss-set',
     'cat-0001-0000-0000-0000-000000000005','Stabilo','ADET',
     'Stabilo Boss fosforlu kalem 6li set',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Leitz A4 Plastik Dosya','PRD-LEITZ-A4','leitz-a4-plastik-dosya',
     'cat-0001-0000-0000-0000-000000000005','Leitz','KUTU',
     'Leitz A4 sirti acik plastik dosya 100lu kutu',false,'ACTIVE'),

    ('prd-00001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Scotch Bant 19mm x 33m','PRD-SCOTCH-19','scotch-bant-19mm',
     'cat-0001-0000-0000-0000-000000000005','Scotch','ADET',
     'Scotch seffaf bant 19mm x 33m dispenserli',false,'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 8b. EK VARYANTLAR
-- ================================================

INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, additional_price, attributes, product_id, is_deleted)
VALUES
    -- Samsung Galaxy A35 varyantları (TechMobil)
    ('pvr-00001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAM-A35-BLK-128','sam-a35-siyah-128','Samsung Galaxy A35 Siyah 128GB',
     0.00,'{"color":"Siyah","storage":"128 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000005',false),

    ('pvr-00001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAM-A35-LVD-256','sam-a35-lavanta-256','Samsung Galaxy A35 Lavanta 256GB',
     2000.00,'{"color":"Lavanta","storage":"256 GB"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000005',false),

    -- JBL Tune 770NC (TechMobil)
    ('pvr-00001-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JBL-T770-BLK','jbl-t770-siyah','JBL Tune 770NC Siyah',
     0.00,'{"color":"Siyah"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000006',false),

    ('pvr-00001-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JBL-T770-WHT','jbl-t770-beyaz','JBL Tune 770NC Beyaz',
     0.00,'{"color":"Beyaz"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000006',false),

    -- Anker 65W GaN (TechMobil) — tek varyant
    ('pvr-00001-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ANKER-65W-BLK','anker-65w-siyah','Anker 65W GaN Sarj Adaptoru Siyah',
     0.00,'{"color":"Siyah"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000007',false),

    -- Slim Fit Oxford Gomlek (Tekstil Grup)
    ('pvr-00001-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'OXFORD-WHT-M','oxford-beyaz-m','Slim Fit Oxford Gomlek Beyaz M',
     0.00,'{"color":"Beyaz","size":"M"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000008',false),

    ('pvr-00001-0000-0000-0000-000000000017','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'OXFORD-WHT-L','oxford-beyaz-l','Slim Fit Oxford Gomlek Beyaz L',
     0.00,'{"color":"Beyaz","size":"L"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000008',false),

    ('pvr-00001-0000-0000-0000-000000000018','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'OXFORD-LBL-M','oxford-acik-mavi-m','Slim Fit Oxford Gomlek Acik Mavi M',
     0.00,'{"color":"Acik Mavi","size":"M"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000008',false),

    -- Jogger Esofman Alti (Tekstil Grup)
    ('pvr-00001-0000-0000-0000-000000000019','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JOGGER-GRY-M','jogger-gri-m','Jogger Esofman Alti Gri M',
     0.00,'{"color":"Gri","size":"M"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000009',false),

    ('pvr-00001-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JOGGER-GRY-L','jogger-gri-l','Jogger Esofman Alti Gri L',
     0.00,'{"color":"Gri","size":"L"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000009',false),

    ('pvr-00001-0000-0000-0000-000000000021','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'JOGGER-NVY-L','jogger-lacivert-l','Jogger Esofman Alti Lacivert L',
     0.00,'{"color":"Lacivert","size":"L"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000009',false),

    -- Stabilo Boss Seti (Genel Dagitim)
    ('pvr-00001-0000-0000-0000-000000000022','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'STABILO-BOSS-6LI','stabilo-boss-6li','Stabilo Boss Highlighter 6li Set',
     0.00,'{"content":"6 Renk"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000010',false),

    -- Leitz A4 Dosya (Genel Dagitim)
    ('pvr-00001-0000-0000-0000-000000000023','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'LEITZ-DOSYA-100','leitz-dosya-100lu','Leitz A4 Plastik Dosya 100lu Kutu',
     0.00,'{"content":"100 Adet/Kutu"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000011',false),

    -- Scotch Bant (Genel Dagitim)
    ('pvr-00001-0000-0000-0000-000000000024','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SCOTCH-19MM','scotch-bant-19mm','Scotch Bant 19mm x 33m Dispenserli',
     0.00,'{"size":"19mm x 33m"}'::jsonb,
     'prd-00001-0000-0000-0000-000000000012',false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 9. BARCODES  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO barcodes
(id, create_user, company_code, create_time, last_modified_time,
 barcode_code, barcode_type, is_primary, is_active, usage_count, variant_id)
VALUES
    ('bar-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000001','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000001'),
    ('bar-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000002','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000002'),
    ('bar-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000003','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000003'),
    ('bar-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000004','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000004'),
    ('bar-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000005','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000005'),
    ('bar-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000006','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000006'),
    ('bar-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000007','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000007'),
    ('bar-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000008','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000008'),
    ('bar-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000009','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000009'),
    ('bar-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000010','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000010')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 10. VARIANT_PRICING  (TOpenSimpleCompanyEntity)
--     valid_from zorunlu - Java default'u yok
-- ================================================
INSERT INTO variant_pricing
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, purchase_price, sale_price, currency, valid_from,
 vat_rate, vat_included, tax_exempt)
VALUES
    ('vpr-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000001',12500.00,17999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000002',12500.00,17999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000003',14000.00,19499.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000004',42000.00,59999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000005',52000.00,69999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000006',120.00,299.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000007',120.00,299.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000008',120.00,299.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000009',15.00,49.90,'TRY',CURRENT_TIMESTAMP,    1.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000010',15.00,49.90,'TRY',CURRENT_TIMESTAMP,    1.00,false,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 10b. EK BARKODLAR (pvr-011 → pvr-024)
-- ================================================
INSERT INTO barcodes
(id, create_user, company_code, create_time, last_modified_time,
 barcode_code, barcode_type, is_primary, is_active, usage_count, variant_id)
VALUES
    ('bar-00001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000011','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000011'),
    ('bar-00001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000012','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000012'),
    ('bar-00001-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000013','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000013'),
    ('bar-00001-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000014','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000014'),
    ('bar-00001-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000015','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000015'),
    ('bar-00001-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000016','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000016'),
    ('bar-00001-0000-0000-0000-000000000017','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000017','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000017'),
    ('bar-00001-0000-0000-0000-000000000018','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000018','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000018'),
    ('bar-00001-0000-0000-0000-000000000019','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000019','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000019'),
    ('bar-00001-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000020','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000020'),
    ('bar-00001-0000-0000-0000-000000000021','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000021','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000021'),
    ('bar-00001-0000-0000-0000-000000000022','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000022','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000022'),
    ('bar-00001-0000-0000-0000-000000000023','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000023','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000023'),
    ('bar-00001-0000-0000-0000-000000000024','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     '8690000000024','EAN13',true,true,0,'pvr-00001-0000-0000-0000-000000000024')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 10c. EK FİYATLAR (pvr-011 → pvr-024)
-- ================================================
INSERT INTO variant_pricing
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, purchase_price, sale_price, currency, valid_from,
 vat_rate, vat_included, tax_exempt)
VALUES
    -- Samsung A35
    ('vpr-00001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000011', 9500.00, 13999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000012',11500.00, 15999.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    -- JBL T770
    ('vpr-00001-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000013', 2200.00,  3499.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000014', 2200.00,  3499.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    -- Anker 65W
    ('vpr-00001-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000015',  480.00,   849.00,'TRY',CURRENT_TIMESTAMP, 20.00,false,false),
    -- Oxford Gomlek
    ('vpr-00001-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000016',  150.00,   399.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000017','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000017',  150.00,   399.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000018','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000018',  150.00,   399.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    -- Jogger
    ('vpr-00001-0000-0000-0000-000000000019','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000019',  180.00,   449.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000020','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000020',  180.00,   449.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    ('vpr-00001-0000-0000-0000-000000000021','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000021',  180.00,   449.00,'TRY',CURRENT_TIMESTAMP,  8.00,false,false),
    -- Stabilo Boss
    ('vpr-00001-0000-0000-0000-000000000022','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000022',   60.00,   129.00,'TRY',CURRENT_TIMESTAMP,  1.00,false,false),
    -- Leitz Dosya
    ('vpr-00001-0000-0000-0000-000000000023','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000023',  320.00,   549.00,'TRY',CURRENT_TIMESTAMP,  1.00,false,false),
    -- Scotch Bant
    ('vpr-00001-0000-0000-0000-000000000024','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000024',   18.00,    39.90,'TRY',CURRENT_TIMESTAMP,  1.00,false,false)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 11. STOCK_MOVEMENTS - Giris (PURCHASE_IN)
-- ================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, store_id, warehouse_id, movement_type, quantity)
VALUES
    ('sm-000001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000001','STORE-01','WH-01','PURCHASE_IN',20),
    ('sm-000001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000002','STORE-01','WH-01','PURCHASE_IN',15),
    ('sm-000001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000003','STORE-01','WH-01','PURCHASE_IN',10),
    ('sm-000001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000004','STORE-01','WH-01','PURCHASE_IN',8),
    ('sm-000001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000005','STORE-01','WH-01','PURCHASE_IN',5),
    ('sm-000001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000006','STORE-01','WH-01','PURCHASE_IN',50),
    ('sm-000001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000007','STORE-01','WH-01','PURCHASE_IN',50),
    ('sm-000001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000008','STORE-01','WH-01','PURCHASE_IN',50),
    ('sm-000001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000009','STORE-01','WH-01','PURCHASE_IN',200),
    ('sm-000001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000010','STORE-01','WH-01','PURCHASE_IN',200)
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 12. SALES  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO sales
(id, create_user, company_code, create_time, last_modified_time,
 sale_number, sale_date, customer_id, total_amount, paid_amount, is_cancelled)
VALUES
    ('sal-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAL-2026-001',CURRENT_TIMESTAMP,'cus-00001-0000-0000-0000-000000000001',17999.00,17999.00,false),

    ('sal-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SAL-2026-002',CURRENT_TIMESTAMP,'cus-00001-0000-0000-0000-000000000002',59999.00,10000.00,false)
ON CONFLICT (id) DO NOTHING;

-- Satis stok cikisi (SALE_OUT)
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, store_id, warehouse_id, movement_type, quantity, sale_id)
VALUES
    ('sm-000001-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000001','STORE-01','WH-01','SALE_OUT',1,
     'sal-00001-0000-0000-0000-000000000001'),

    ('sm-000001-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'pvr-00001-0000-0000-0000-000000000004','STORE-01','WH-01','SALE_OUT',1,
     'sal-00001-0000-0000-0000-000000000002')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 13. PAYMENTS  (TOpenSimpleCompanyEntity)
-- ================================================
INSERT INTO payments
(id, create_user, company_code, create_time, last_modified_time,
 customer_id, sale_id, payment_type, amount, payment_date, description,
 is_cancelled, is_verified)
VALUES
    ('pay-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-00001-0000-0000-0000-000000000001','sal-00001-0000-0000-0000-000000000001',
     'CASH',17999.00,CURRENT_TIMESTAMP,'SAL-2026-001 nakit tahsilat',false,true),

    ('pay-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'cus-00001-0000-0000-0000-000000000002','sal-00001-0000-0000-0000-000000000002',
     'BANK_TRANSFER',10000.00,CURRENT_TIMESTAMP,'SAL-2026-002 kapora odemesi',false,false)
ON CONFLICT (id) DO NOTHING;
insert into role_def (id, create_time, create_user, last_modified_time, update_user, company_code, code, description,
                      is_active, is_system_role, name)
values ('6d728059-90fb-4753-b295-953c3c5b2035', '2011-05-16 15:36:38', 'sedat', '2011-05-16 15:36:38', null, 'SEDCORE',
        'USER', 'user role', true, true, 'sedat');

insert into user_def (id, create_time, create_user, last_modified_time, update_user, company_code, generic_identifier,
                      is_active, language_val, user_def_generic_id_type, user_display_name, user_name, user_type)
values ('6d728059-90fb-4753-b295-953c3c5b2036', '2011-05-16 15:36:38', 'sedat', '2011-05-16 15:36:38', null, 'SEDCORE',
        'generic_identifier', true, 'TR', 'AGENCY_ID', 'user display name', 'sedat', 'USER');

insert into user_def_access (id, create_time, create_user, last_modified_time, update_user, company_code, access_type,
                             can_login, has_ip_restriction, ip_restriction, is_force_password_change, last_change_time,
                             password_hash, salt_key, user_def_id)
values ('6d728059-90fb-4753-b295-953c3c5b2037', '2011-05-16 15:36:38', 'sedat', '2011-05-16 15:36:38', null, 'SEDCORE',
        'INTERNAL', true, true, true, true, '2011-05-16 15:36:38', 'icerwJaNuMo0cknO9Ue/PfwtvuzD3FMs32OrjN8H8p0=',
        'sedcore', '6d728059-90fb-4753-b295-953c3c5b2036');

insert into user_role (id, create_time, create_user, last_modified_time, update_user, company_code, role_def_id,
                       user_def_id)
values ('6d728059-90fb-4753-b295-953c3c5b2038', '2011-05-16 15:36:38', 'sedat', '2011-05-16 15:36:38', null, 'SEDCORE',
        '6d728059-90fb-4753-b295-953c3c5b2035', '6d728059-90fb-4753-b295-953c3c5b2036');





select * from user_def_access;

-- ================================================
-- 14. PURCHASES  (Satın Alma Kayıtları)
-- ================================================
-- PUR-2026-001 : TechMobil  — Samsung A54 + MacBook  → Açık borç
-- PUR-2026-002 : Tekstil Grup — T-Shirt çeşitleri    → Kısmi ödeme
-- PUR-2026-003 : Genel Dağıtım — Kalem               → Tam ödendi
-- PUR-2026-004 : TechMobil  — Samsung A35 + JBL      → Açık borç (yeni)
-- PUR-2026-005 : Tekstil Grup — Jogger               → İPTAL EDİLDİ
-- ================================================
INSERT INTO purchases
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, purchase_date, invoice_number, delivery_note_number,
 total_amount, paid_amount, is_cancelled, notes)
VALUES
    ('pur-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000001',
     '2026-01-15','INV-TM-2026-0031','IRS-TM-2026-0031',
     460000.00, 0.00, false,
     'Samsung A54 x20 + MacBook Air M2 x5 — Vadeli alım'),

    ('pur-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000002',
     '2026-01-20','INV-TG-2026-0044','IRS-TG-2026-0044',
     33600.00, 15000.00, false,
     'Basic T-Shirt stok yenilemesi — kısmi ödeme yapıldı'),

    ('pur-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000003',
     '2026-02-01','INV-GD-2026-0112','IRS-GD-2026-0112',
     15000.00, 15000.00, false,
     'Pilot G2 kalem toplu alım — peşin ödendi'),

    ('pur-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000001',
     '2026-02-20','INV-TM-2026-0058','IRS-TM-2026-0058',
     318000.00, 100000.00, false,
     'Samsung A35 x30 + JBL T770 x15 — kapora alındı'),

    ('pur-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'sup-00001-0000-0000-0000-000000000002',
     '2026-03-05','INV-TG-2026-0089','IRS-TG-2026-0089',
     9000.00, 0.00, true,
     'Jogger Eşofman — hasarlı sevkiyat, iade edildi (iptal)')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 14b. PURCHASE STOK HAREKETLERİ (PURCHASE_IN)
-- ================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, store_id, warehouse_id, movement_type, quantity, purchase_id)
VALUES
    -- PUR-001: Samsung A54 Siyah 128GB x20
    ('sm-000002-0000-0000-0000-000000000001','SYSTEM','SEDCORE','2026-01-15 10:00:00','2026-01-15 10:00:00',
     'pvr-00001-0000-0000-0000-000000000001','STORE-01','WH-01','PURCHASE_IN',20,
     'pur-00001-0000-0000-0000-000000000001'),

    -- PUR-001: MacBook Air M2 Gece Yarısı 256GB x5
    ('sm-000002-0000-0000-0000-000000000002','SYSTEM','SEDCORE','2026-01-15 10:00:00','2026-01-15 10:00:00',
     'pvr-00001-0000-0000-0000-000000000004','STORE-01','WH-01','PURCHASE_IN',5,
     'pur-00001-0000-0000-0000-000000000001'),

    -- PUR-002: T-Shirt Lacivert M x100
    ('sm-000002-0000-0000-0000-000000000003','SYSTEM','SEDCORE','2026-01-20 09:30:00','2026-01-20 09:30:00',
     'pvr-00001-0000-0000-0000-000000000006','STORE-01','WH-01','PURCHASE_IN',100,
     'pur-00001-0000-0000-0000-000000000002'),

    -- PUR-002: T-Shirt Lacivert L x100
    ('sm-000002-0000-0000-0000-000000000004','SYSTEM','SEDCORE','2026-01-20 09:30:00','2026-01-20 09:30:00',
     'pvr-00001-0000-0000-0000-000000000007','STORE-01','WH-01','PURCHASE_IN',100,
     'pur-00001-0000-0000-0000-000000000002'),

    -- PUR-002: T-Shirt Beyaz M x80
    ('sm-000002-0000-0000-0000-000000000005','SYSTEM','SEDCORE','2026-01-20 09:30:00','2026-01-20 09:30:00',
     'pvr-00001-0000-0000-0000-000000000008','STORE-01','WH-01','PURCHASE_IN',80,
     'pur-00001-0000-0000-0000-000000000002'),

    -- PUR-003: Pilot G2 Mavi x500
    ('sm-000002-0000-0000-0000-000000000006','SYSTEM','SEDCORE','2026-02-01 11:00:00','2026-02-01 11:00:00',
     'pvr-00001-0000-0000-0000-000000000009','STORE-01','WH-01','PURCHASE_IN',500,
     'pur-00001-0000-0000-0000-000000000003'),

    -- PUR-003: Pilot G2 Siyah x500
    ('sm-000002-0000-0000-0000-000000000007','SYSTEM','SEDCORE','2026-02-01 11:00:00','2026-02-01 11:00:00',
     'pvr-00001-0000-0000-0000-000000000010','STORE-01','WH-01','PURCHASE_IN',500,
     'pur-00001-0000-0000-0000-000000000003'),

    -- PUR-004: Samsung A35 Siyah 128GB x30
    ('sm-000002-0000-0000-0000-000000000008','SYSTEM','SEDCORE','2026-02-20 14:00:00','2026-02-20 14:00:00',
     'pvr-00001-0000-0000-0000-000000000011','STORE-01','WH-01','PURCHASE_IN',30,
     'pur-00001-0000-0000-0000-000000000004'),

    -- PUR-004: JBL Tune 770NC Siyah x15
    ('sm-000002-0000-0000-0000-000000000009','SYSTEM','SEDCORE','2026-02-20 14:00:00','2026-02-20 14:00:00',
     'pvr-00001-0000-0000-0000-000000000013','STORE-01','WH-01','PURCHASE_IN',15,
     'pur-00001-0000-0000-0000-000000000004'),

    -- PUR-005 (İPTAL): Jogger Gri M x50 giriş
    ('sm-000002-0000-0000-0000-000000000010','SYSTEM','SEDCORE','2026-03-05 10:00:00','2026-03-05 10:00:00',
     'pvr-00001-0000-0000-0000-000000000019','STORE-01','WH-01','PURCHASE_IN',50,
     'pur-00001-0000-0000-0000-000000000005'),

    -- PUR-005 (İPTAL): Jogger Gri M x50 iade çıkış (PURCHASE_RETURN_OUT)
    ('sm-000002-0000-0000-0000-000000000011','SYSTEM','SEDCORE','2026-03-05 16:00:00','2026-03-05 16:00:00',
     'pvr-00001-0000-0000-0000-000000000019','STORE-01','WH-01','PURCHASE_RETURN_OUT',50,
     'pur-00001-0000-0000-0000-000000000005')
ON CONFLICT (id) DO NOTHING;

-- ================================================
-- 14c. ACCOUNT TRANSACTIONS (Satın alma cari hareketleri)
-- ================================================
INSERT INTO account_transactions
(id, create_user, company_code, create_time, last_modified_time,
 supplier_id, purchase_id,
 transaction_type, debit_amount, credit_amount, balance,
 reference_number, description, transaction_date, is_cancelled)
VALUES
    -- PUR-001: TechMobil borç kaydı
    ('atx-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE','2026-01-15 10:00:00','2026-01-15 10:00:00',
     'sup-00001-0000-0000-0000-000000000001','pur-00001-0000-0000-0000-000000000001',
     'PURCHASE',460000.00,0.00,460000.00,
     'INV-TM-2026-0031','Samsung A54 x20 + MacBook M2 x5','2026-01-15',false),

    -- PUR-002: Tekstil Grup borç kaydı
    ('atx-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE','2026-01-20 09:30:00','2026-01-20 09:30:00',
     'sup-00001-0000-0000-0000-000000000002','pur-00001-0000-0000-0000-000000000002',
     'PURCHASE',33600.00,0.00,33600.00,
     'INV-TG-2026-0044','T-Shirt stok yenilemesi','2026-01-20',false),

    -- PUR-002: Kısmi ödeme
    ('atx-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE','2026-01-22 11:00:00','2026-01-22 11:00:00',
     'sup-00001-0000-0000-0000-000000000002',NULL,
     'SUPPLIER_PAYMENT',0.00,15000.00,18600.00,
     'OD-TG-2026-0022','INV-TG-2026-0044 kismi odeme','2026-01-22',false),

    -- PUR-003: Genel Dagitim borc kaydi
    ('atx-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE','2026-02-01 11:00:00','2026-02-01 11:00:00',
     'sup-00001-0000-0000-0000-000000000003','pur-00001-0000-0000-0000-000000000003',
     'PURCHASE',15000.00,0.00,15000.00,
     'INV-GD-2026-0112','Pilot G2 x1000 toplu alım','2026-02-01',false),

    -- PUR-003: Tam ödeme
    ('atx-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE','2026-02-01 15:00:00','2026-02-01 15:00:00',
     'sup-00001-0000-0000-0000-000000000003',NULL,
     'SUPPLIER_PAYMENT',0.00,15000.00,0.00,
     'OD-GD-2026-0058','INV-GD-2026-0112 tam odeme','2026-02-01',false),

    -- PUR-004: TechMobil borç kaydı
    ('atx-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE','2026-02-20 14:00:00','2026-02-20 14:00:00',
     'sup-00001-0000-0000-0000-000000000001','pur-00001-0000-0000-0000-000000000004',
     'PURCHASE',318000.00,0.00,778000.00,
     'INV-TM-2026-0058','Samsung A35 x30 + JBL T770 x15','2026-02-20',false),

    -- PUR-004: Kapora ödemesi
    ('atx-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE','2026-02-20 14:30:00','2026-02-20 14:30:00',
     'sup-00001-0000-0000-0000-000000000001',NULL,
     'SUPPLIER_PAYMENT',0.00,100000.00,678000.00,
     'OD-TM-2026-0079','INV-TM-2026-0058 kapora','2026-02-20',false),

    -- PUR-005: Tekstil Grup borç kaydı (iptal öncesi)
    ('atx-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE','2026-03-05 10:00:00','2026-03-05 10:00:00',
     'sup-00001-0000-0000-0000-000000000002','pur-00001-0000-0000-0000-000000000005',
     'PURCHASE',9000.00,0.00,27600.00,
     'INV-TG-2026-0089','Jogger Eşofman x50','2026-03-05',true),

    -- PUR-005: İptal ters kaydı
    ('atx-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE','2026-03-05 16:00:00','2026-03-05 16:00:00',
     'sup-00001-0000-0000-0000-000000000002','pur-00001-0000-0000-0000-000000000005',
     'SUPPLIER_RETURN',0.00,9000.00,18600.00,
     'INV-TG-2026-0089-IADE','Jogger Eşofman iade — hasarlı sevkiyat','2026-03-05',false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- BRANDS (Markalar) — SEDCORE firması için
-- ============================================================
INSERT INTO brands
(id, create_user, company_code, create_time, last_modified_time, name, code, description, is_active)
VALUES
    ('brd-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Nike','NIKE','Spor giyim ve ayakkabı',true),
    ('brd-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Adidas','ADIDAS','Spor giyim ve ayakkabı',true),
    ('brd-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Apple','APPLE','Elektronik ve teknoloji ürünleri',true),
    ('brd-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Samsung','SAMSUNG','Elektronik ve teknoloji ürünleri',true),
    ('brd-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Sony','SONY','Elektronik ve eğlence',true),
    ('brd-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'LG','LG','Elektronik ve beyaz eşya',true),
    ('brd-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Zara','ZARA','Moda ve giyim',true),
    ('brd-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'LC Waikiki','LCWK','Moda ve giyim',true),
    ('brd-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mavi','MAVI','Denim ve moda',true),
    ('brd-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Marka Tekstil','MRKTX','Yerli tekstil üreticisi',true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- UNITS (Birimler) — SEDCORE firması için
-- ============================================================
INSERT INTO units
(id, create_user, company_code, create_time, last_modified_time, code, name, symbol, type, is_active)
VALUES
    ('unt-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'ADET','Adet','pcs','Sayılabilir',true),
    ('unt-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'KG','Kilogram','kg','Tartılabilir',true),
    ('unt-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'GR','Gram','g','Tartılabilir',true),
    ('unt-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'LT','Litre','L','Ölçülebilir',true),
    ('unt-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'MT','Metre','m','Ölçülebilir',true),
    ('unt-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'M2','Metrekare','m²','Ölçülebilir',true),
    ('unt-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'KUTU','Kutu','box','Sayılabilir',true),
    ('unt-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'PAKET','Paket','pkg','Sayılabilir',true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PARCACI (OTO YEDEK PARCA) SEED DATA
-- ============================================================

-- ============================================================
-- OTO YEDEK PARCA KATEGORILERI
-- ============================================================
INSERT INTO categories
(id, create_user, create_time, last_modified_time,
 name, slug, description, image_url, icon, sort_order, level, path,
 is_deleted, status, metadata, meta_title, meta_description, meta_keywords)
VALUES
    ('cat-auto-0000-0000-0000-000000000001','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fren Sistemi','fren-sistemi','Fren balatalari, diskleri ve parcalari',NULL,'build',10,0,'/fren-sistemi',
     false,'ACTIVE','{}'::jsonb,'Fren Sistemi','Fren sistem parcalari','fren,balata,disk,kampana'),
    ('cat-auto-0000-0000-0000-000000000002','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Suspan Sistemi','suspansiyon','Amortisör, rotil, bilyali baslik',NULL,'settings',11,0,'/suspansiyon',
     false,'ACTIVE','{}'::jsonb,'Suspansiyon','Suspansiyon parcalari','amortisor,rotil,rot,salincak'),
    ('cat-auto-0000-0000-0000-000000000003','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Motor Parcalari','motor-parcalari','Motor ic parcalari ve contalar',NULL,'engineering',12,0,'/motor-parcalari',
     false,'ACTIVE','{}'::jsonb,'Motor Parcalari','Motor parcalari','motor,conta,piston,supap'),
    ('cat-auto-0000-0000-0000-000000000004','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Filtreler','filtreler','Yag, hava, yakit ve kabin filtreleri',NULL,'filter_alt',13,0,'/filtreler',
     false,'ACTIVE','{}'::jsonb,'Filtreler','Filtre cesitleri','filtre,yag,hava,yakit,kabin'),
    ('cat-auto-0000-0000-0000-000000000005','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Aydinlatma','aydinlatma','Far, stop, sinyal lambalari',NULL,'lightbulb',14,0,'/aydinlatma',
     false,'ACTIVE','{}'::jsonb,'Aydinlatma','Aydinlatma parcalari','far,stop,sinyal,ampul'),
    ('cat-auto-0000-0000-0000-000000000006','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Elektrik ve Akü','elektrik-aku','Akü, alternator, marş motoru',NULL,'bolt',15,0,'/elektrik-aku',
     false,'ACTIVE','{}'::jsonb,'Elektrik Aku','Elektrik ve aku parcalari','aku,alternator,mars,buji'),
    ('cat-auto-0000-0000-0000-000000000007','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Sogutma Sistemi','sogutma-sistemi','Radyator, termostat, pompa',NULL,'ac_unit',16,0,'/sogutma-sistemi',
     false,'ACTIVE','{}'::jsonb,'Sogutma','Sogutma sistemi parcalari','radyator,termostat,devirdaim,antifriz'),
    ('cat-auto-0000-0000-0000-000000000008','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Egzoz Sistemi','egzoz-sistemi','Egzoz borusu, katalizor, susturucu',NULL,'air',17,0,'/egzoz-sistemi',
     false,'ACTIVE','{}'::jsonb,'Egzoz','Egzoz sistemi parcalari','egzoz,katalizor,susturucu'),
    ('cat-auto-0000-0000-0000-000000000009','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Debriyaj ve Sanziman','debriyaj-sanziman','Debriyaj seti, volant, sanziman parcalari',NULL,'settings_applications',18,0,'/debriyaj-sanziman',
     false,'ACTIVE','{}'::jsonb,'Debriyaj Sanziman','Debriyaj ve sanziman parcalari','debriyaj,volant,sanziman,vites'),
    ('cat-auto-0000-0000-0000-000000000010','SYSTEM',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Kayis ve Gergi','kayis-gergi','Triger, V kayis, gergi rulmani',NULL,'sync',19,0,'/kayis-gergi',
     false,'ACTIVE','{}'::jsonb,'Kayis Gergi','Kayis ve gergi parcalari','triger,kayis,gergi,rulman')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- OTO YEDEK PARCA MARKALARI
-- ============================================================
INSERT INTO brands
(id, create_user, company_code, create_time, last_modified_time, name, code, description, is_active)
VALUES
    ('brd-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Bosch','BOSCH','Alman oto yedek parca üreticisi',true),
    ('brd-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'TRW','TRW','Fren ve suspan parcalari',true),
    ('brd-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Valeo','VALEO','Debriyaj ve elektrik parcalari',true),
    ('brd-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mann Filter','MANN','Filtre uzmani',true),
    ('brd-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Brembo','BREMBO','Italyan fren sistemi uzmani',true),
    ('brd-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Sachs','SACHS','Amortisor ve debriyaj',true),
    ('brd-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'SKF','SKF','Rulman ve kayis sistemleri',true),
    ('brd-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Gates','GATES','Kayis ve hortum uzmani',true),
    ('brd-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Mahle','MAHLE','Motor parcalari ve filtreler',true),
    ('brd-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'Delphi','DELPHI','Yakit sistemi ve elektrik',true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ARACLAR (VEHICLES)
-- ============================================================
INSERT INTO vehicles
(id, create_user, company_code, create_time, last_modified_time,
 make, model, year_start, year_end, engine_type, fuel_type, body_type, platform_code, is_active)
VALUES
    ('veh-00001-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Toyota','Corolla',2013,2018,'1.6 Valvematic','Benzin','Sedan','E170',true),
    ('veh-00001-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Toyota','Corolla',2019,2025,'1.8 Hybrid','Hybrid','Sedan','E210',true),
    ('veh-00001-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Volkswagen','Golf',2013,2019,'1.6 TDI','Dizel','Hatchback','MK7',true),
    ('veh-00001-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Volkswagen','Passat',2015,2023,'1.6 TDI','Dizel','Sedan','B8',true),
    ('veh-00001-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Ford','Focus',2011,2018,'1.6 TDCi','Dizel','Hatchback','MK3',true),
    ('veh-00001-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Renault','Megane',2016,2023,'1.5 dCi','Dizel','Sedan','IV',true),
    ('veh-00001-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Hyundai','Tucson',2015,2020,'1.6 CRDi','Dizel','SUV','TL',true),
    ('veh-00001-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Fiat','Egea',2016,2025,'1.3 MultiJet','Dizel','Sedan','356',true),
    ('veh-00001-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'BMW','3 Serisi',2012,2018,'2.0d','Dizel','Sedan','F30',true),
    ('veh-00001-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Mercedes','C Serisi',2014,2021,'1.6d','Dizel','Sedan','W205',true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- TEDARIKCILER (Oto Yedek Parca)
-- ============================================================
INSERT INTO supplier
(id, create_user, company_code, create_time, last_modified_time,
 name, contact_name, phone, email, address, notes, customer_type, tax_number, tax_office,
 credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('sup-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Bosch Turkiye','Ahmet Yilmaz','0212 335 00 00','satis@bosch.com.tr','Bursa Organize Sanayi','Ana Bosch distribütörü','CORPORATE','1234567890','Bursa',
     500000.00,60,'NORMAL',true,false),
    ('sup-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Otopar Yedek Parca','Mehmet Demir','0212 612 00 00','info@otopar.com.tr','Istanbul Perpa Ticaret Merkezi','Genel oto yedek parca toptancisi','CORPORATE','9876543210','Istanbul',
     200000.00,30,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- MUSTERILER (Oto Yedek Parca)
-- ============================================================
INSERT INTO customer
(id, create_user, company_code, create_time, last_modified_time,
 name, phone, email, address, notes, customer_type, tax_number, tax_office,
 credit_limit, payment_term_days, risk_status, is_active, is_deleted)
VALUES
    ('cust-auto-000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Usta Motor Tamir','0532 111 22 33','usta@email.com','Kadikoy, Istanbul','Duzenlimüsteri, aylık ödeme','CORPORATE','1112223334','Istanbul',
     50000.00,30,'NORMAL',true,false),
    ('cust-auto-000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Yildiz Oto Servis','0533 444 55 66','yildiz@email.com','Atasehir, Istanbul','Buyuk servis, haftalik siparis','CORPORATE','5556667778','Istanbul',
     100000.00,15,'NORMAL',true,false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- URUNLER (Oto Yedek Parcalar) — 10 adet
-- ============================================================
INSERT INTO products
(id, create_user, company_code, create_time, last_modified_time,
 name, sku, slug, category_id, brand, unit, description, is_deleted, status)
VALUES
    ('prd-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'On Fren Balata Seti','FRN-BLT-001','on-fren-balata-seti','cat-auto-0000-0000-0000-000000000001','Bosch','ADET','On teker fren balata takimi',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Arka Fren Balata Seti','FRN-BLT-002','arka-fren-balata-seti','cat-auto-0000-0000-0000-000000000001','TRW','ADET','Arka teker fren balata takimi',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'On Fren Diski','FRN-DSK-001','on-fren-diski','cat-auto-0000-0000-0000-000000000001','Brembo','ADET','On fren diski (ventilasyonlu)',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Yag Filtresi','FLT-YAG-001','yag-filtresi','cat-auto-0000-0000-0000-000000000004','Mann Filter','ADET','Motor yag filtresi',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Hava Filtresi','FLT-HVA-001','hava-filtresi','cat-auto-0000-0000-0000-000000000004','Mahle','ADET','Motor hava filtresi',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'On Amortisor','SUS-AMR-001','on-amortisor','cat-auto-0000-0000-0000-000000000002','Sachs','ADET','On amortisor (sol/sag)',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Debriyaj Seti','DBR-SET-001','debriyaj-seti','cat-auto-0000-0000-0000-000000000009','Valeo','ADET','3 parca debriyaj seti (baskı, balata, rulman)',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Triger Seti','KYS-TRG-001','triger-seti','cat-auto-0000-0000-0000-000000000010','Gates','ADET','Triger kayis + gergi + avare seti',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Buji Takimi (4lu)','ELK-BJI-001','buji-takimi','cat-auto-0000-0000-0000-000000000006','Bosch','ADET','4 adet ateslemeli buji seti',false,'ACTIVE'),
    ('prd-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'Devirdaim Pompasi','SGT-DVR-001','devirdaim-pompasi','cat-auto-0000-0000-0000-000000000007','SKF','ADET','Su pompasi / devirdaim',false,'ACTIVE')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- URUN VARYANTLARI — her ürün için 1 varyant
-- ============================================================
INSERT INTO product_variants
(id, create_user, company_code, create_time, last_modified_time,
 sku, slug, name, product_id, is_deleted, min_stock_level, shelf_location_code, additional_price)
VALUES
    ('var-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-BLT-001-V1','on-fren-balata-v1','On Fren Balata - Standart','prd-auto-0000-0000-0000-000000000001',false,5,'A-1-01',0.00),
    ('var-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-BLT-002-V1','arka-fren-balata-v1','Arka Fren Balata - Standart','prd-auto-0000-0000-0000-000000000002',false,5,'A-1-02',0.00),
    ('var-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FRN-DSK-001-V1','on-fren-diski-v1','On Fren Diski - Ventilasyonlu','prd-auto-0000-0000-0000-000000000003',false,4,'A-2-01',0.00),
    ('var-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FLT-YAG-001-V1','yag-filtresi-v1','Yag Filtresi - Standart','prd-auto-0000-0000-0000-000000000004',false,10,'B-1-01',0.00),
    ('var-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'FLT-HVA-001-V1','hava-filtresi-v1','Hava Filtresi - Standart','prd-auto-0000-0000-0000-000000000005',false,10,'B-1-02',0.00),
    ('var-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SUS-AMR-001-V1','on-amortisor-v1','On Amortisor - Gaz','prd-auto-0000-0000-0000-000000000006',false,3,'C-1-01',0.00),
    ('var-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'DBR-SET-001-V1','debriyaj-seti-v1','Debriyaj Seti - 3 Parca','prd-auto-0000-0000-0000-000000000007',false,2,'C-2-01',0.00),
    ('var-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'KYS-TRG-001-V1','triger-seti-v1','Triger Seti - Komple','prd-auto-0000-0000-0000-000000000008',false,3,'C-3-01',0.00),
    ('var-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'ELK-BJI-001-V1','buji-takimi-v1','Buji Takimi - Iridyum','prd-auto-0000-0000-0000-000000000009',false,8,'D-1-01',0.00),
    ('var-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'SGT-DVR-001-V1','devirdaim-v1','Devirdaim Pompasi - Standart','prd-auto-0000-0000-0000-000000000010',false,3,'D-2-01',0.00)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- VARYANT FIYATLANDIRMA
-- ============================================================
INSERT INTO variant_pricing
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, purchase_price, sale_price, currency, vat_rate, special_tax_rate, vat_included, withholding_tax_rate, tax_exempt)
VALUES
    ('vpr-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001',180.00,320.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002',150.00,270.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003',450.00,780.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004',45.00,85.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005',60.00,110.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006',650.00,1100.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007',1200.00,2100.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008',800.00,1400.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009',120.00,220.00,'TRY',20.00,0.00,true,0.00,false),
    ('vpr-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010',350.00,620.00,'TRY',20.00,0.00,true,0.00,false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- BARKODLAR
-- ============================================================
INSERT INTO barcodes
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, barcode_code, barcode_type, is_primary, is_active, usage_count)
VALUES
    ('brc-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','8690000001011','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002','8690000001028','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','8690000001035','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','8690000001042','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005','8690000001059','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006','8690000001066','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007','8690000001073','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','8690000001080','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009','8690000001097','EAN13',true,true,0),
    ('brc-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010','8690000001103','EAN13',true,true,0)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- OEM NUMARALARI — her parca icin gercekci OEM numaralari
-- ============================================================
INSERT INTO oem_numbers
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, oem_number, manufacturer, is_primary)
VALUES
    -- On Fren Balata
    ('oem-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','04465-02220','Toyota',true),
    ('oem-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','04465-02230','Toyota',false),
    -- Arka Fren Balata
    ('oem-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002','04466-02181','Toyota',true),
    -- On Fren Diski
    ('oem-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','43512-02330','Toyota',true),
    -- Yag Filtresi
    ('oem-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','03L 115 561B','Volkswagen',true),
    ('oem-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','03L 115 561','Volkswagen',false),
    -- Hava Filtresi
    ('oem-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005','28113-D3100','Hyundai',true),
    -- On Amortisor
    ('oem-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006','54651-D7100','Hyundai',true),
    -- Debriyaj Seti
    ('oem-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007','55570661','Fiat',true),
    -- Triger Seti
    ('oem-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','03L 109 244','Volkswagen',true),
    -- Buji
    ('oem-auto-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009','18846-11070','Hyundai',true),
    -- Devirdaim
    ('oem-auto-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010','16100-09520','Toyota',true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- CAPRAZ REFERANSLAR — muadil parca numaralari
-- ============================================================
INSERT INTO cross_references
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, cross_ref_number, cross_ref_brand, notes)
VALUES
    -- On Fren Balata → muadil markalar
    ('crf-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','GDB3550','TRW','TRW muadili'),
    ('crf-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','BP43263','Brembo','Brembo muadili'),
    -- Arka Fren Balata
    ('crf-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002','GDB3568','TRW','TRW muadili'),
    -- On Fren Diski
    ('crf-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','09.C112.11','Brembo','Brembo orijinal'),
    -- Yag Filtresi
    ('crf-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','W 712/94','Mann Filter','Mann muadili'),
    ('crf-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','0451103318','Bosch','Bosch muadili'),
    -- Hava Filtresi
    ('crf-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005','LX 3539','Mahle','Mahle muadili'),
    -- Amortisor
    ('crf-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006','315 700','Sachs','Sachs muadili'),
    -- Debriyaj Seti
    ('crf-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007','826818','Valeo','Valeo orijinal'),
    -- Triger Seti
    ('crf-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','K015603XS','Gates','Gates orijinal')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ARAC UYUMLULUKLARI — hangi parca hangi araca uyar
-- ============================================================
INSERT INTO vehicle_compatibilities
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, vehicle_id, notes, is_verified)
VALUES
    -- On Fren Balata → Toyota Corolla (2013-2018), Toyota Corolla (2019-2025)
    ('vc-auto-0000-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','veh-00001-0000-0000-0000-000000000001','On fren',true),
    ('vc-auto-0000-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','veh-00001-0000-0000-0000-000000000002','On fren',true),
    -- Arka Fren Balata → Toyota Corolla (2013-2018)
    ('vc-auto-0000-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002','veh-00001-0000-0000-0000-000000000001','Arka fren',true),
    -- On Fren Diski → VW Golf, VW Passat
    ('vc-auto-0000-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','veh-00001-0000-0000-0000-000000000003','On disk',true),
    ('vc-auto-0000-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','veh-00001-0000-0000-0000-000000000004','On disk',true),
    -- Yag Filtresi → VW Golf, VW Passat, Ford Focus
    ('vc-auto-0000-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','veh-00001-0000-0000-0000-000000000003','1.6 TDI',true),
    ('vc-auto-0000-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','veh-00001-0000-0000-0000-000000000004','1.6 TDI',true),
    -- Hava Filtresi → Hyundai Tucson
    ('vc-auto-0000-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005','veh-00001-0000-0000-0000-000000000007','1.6 CRDi',true),
    -- Amortisor → Hyundai Tucson
    ('vc-auto-0000-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006','veh-00001-0000-0000-0000-000000000007','On sol/sag',true),
    -- Debriyaj Seti → Fiat Egea
    ('vc-auto-0000-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007','veh-00001-0000-0000-0000-000000000008','1.3 MultiJet',true),
    -- Triger Seti → VW Golf, VW Passat
    ('vc-auto-0000-0000-0000-0000-000000000011','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','veh-00001-0000-0000-0000-000000000003','1.6 TDI',true),
    ('vc-auto-0000-0000-0000-0000-000000000012','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','veh-00001-0000-0000-0000-000000000004','1.6 TDI',true),
    -- Buji → Toyota Corolla (2013-2018), Hyundai Tucson
    ('vc-auto-0000-0000-0000-0000-000000000013','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009','veh-00001-0000-0000-0000-000000000001','Benzinli model',true),
    ('vc-auto-0000-0000-0000-0000-000000000014','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009','veh-00001-0000-0000-0000-000000000007','Benzinli model',false),
    -- Devirdaim → Toyota Corolla (2013-2018), Renault Megane
    ('vc-auto-0000-0000-0000-0000-000000000015','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010','veh-00001-0000-0000-0000-000000000001','1.6 motor',true),
    ('vc-auto-0000-0000-0000-0000-000000000016','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010','veh-00001-0000-0000-0000-000000000006','1.5 dCi',false)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STOK HAREKETLERI — baslangic stoku (PURCHASE_IN)
-- ============================================================
INSERT INTO stock_movements
(id, create_user, company_code, create_time, last_modified_time,
 variant_id, store_id, warehouse_id, movement_type, quantity)
VALUES
    ('stm-auto-0000-0000-0000-000000000001','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000001','STORE-01','WH-01','PURCHASE_IN',20),
    ('stm-auto-0000-0000-0000-000000000002','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000002','STORE-01','WH-01','PURCHASE_IN',15),
    ('stm-auto-0000-0000-0000-000000000003','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000003','STORE-01','WH-01','PURCHASE_IN',12),
    ('stm-auto-0000-0000-0000-000000000004','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000004','STORE-01','WH-01','PURCHASE_IN',50),
    ('stm-auto-0000-0000-0000-000000000005','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000005','STORE-01','WH-01','PURCHASE_IN',40),
    ('stm-auto-0000-0000-0000-000000000006','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000006','STORE-01','WH-01','PURCHASE_IN',8),
    ('stm-auto-0000-0000-0000-000000000007','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000007','STORE-01','WH-01','PURCHASE_IN',6),
    ('stm-auto-0000-0000-0000-000000000008','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000008','STORE-01','WH-01','PURCHASE_IN',10),
    ('stm-auto-0000-0000-0000-000000000009','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000009','STORE-01','WH-01','PURCHASE_IN',30),
    ('stm-auto-0000-0000-0000-000000000010','SYSTEM','SEDCORE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
     'var-auto-0000-0000-0000-000000000010','STORE-01','WH-01','PURCHASE_IN',7)
ON CONFLICT (id) DO NOTHING;
