-- ============================================================
-- Security Module - Seed Data
-- Şifre algoritması: PBKDF2WithHmacSHA1, 1024 iterasyon, 256-bit
-- ============================================================

-- ============================================================
-- ROL TANIMLAMALARI
-- ============================================================
INSERT INTO role_def (id, create_time, create_user, last_modified_time, update_user,
                      company_code, code, description, is_active, is_system_role, name)
VALUES
    -- Yönetici rolü
    ('role-admin-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'ADMIN', 'Tam yetkili yönetici rolü', true, true, 'Yönetici'),

    -- Kasiyer rolü
    ('role-kasiy-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'CASHIER', 'POS satış ve müşteri işlemleri', true, false, 'Kasiyer'),

    -- Depo sorumlusu rolü
    ('role-depo0-0000-0000-0000-000000000003', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'WAREHOUSE', 'Stok ve depo yönetimi', true, false, 'Depo Sorumlusu'),

    -- Mağaza yöneticisi rolü (giyim)
    ('role-mgzyn-0000-0000-0000-000000000004', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'STORE_MANAGER', 'Mağaza yönetimi ve raporlama', true, false, 'Mağaza Yöneticisi')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- KULLANICI TANIMLAMALARI (user_def)
-- ============================================================
INSERT INTO user_def (id, create_time, create_user, last_modified_time, update_user,
                      company_code, generic_identifier, is_active, language_val,
                      user_def_generic_id_type, user_display_name, user_name, user_type)
VALUES
    -- 1. Admin — Yedek Parça sektörü yöneticisi
    ('udef-admin-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'admin', true, 'TR', 'AGENCY_ID', 'Admin Kullanıcı', 'admin', 'USER'),

    -- 2. Kasiyer — Yedek Parça sektörü kasiyeri
    ('udef-kasiy-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'kasiyer', true, 'TR', 'AGENCY_ID', 'Kasiyer Kullanıcı', 'kasiyer', 'USER'),

    -- 3. Depo — Yedek Parça sektörü depo sorumlusu
    ('udef-depo0-0000-0000-0000-000000000003', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'depo', true, 'TR', 'AGENCY_ID', 'Depo Sorumlusu', 'depo', 'USER'),

    -- 4. Mağaza Admin — Giyim sektörü yöneticisi
    ('udef-mgzad-0000-0000-0000-000000000004', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'magaza_admin', true, 'TR', 'AGENCY_ID', 'Mağaza Yöneticisi', 'magaza_admin', 'USER'),

    -- 5. Giyim Kasiyer — Giyim sektörü kasiyeri
    ('udef-gkasy-0000-0000-0000-000000000005', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'giyim_kasiyer', true, 'TR', 'AGENCY_ID', 'Giyim Kasiyer', 'giyim_kasiyer', 'USER'),

    -- 6. Giyim Depo — Giyim sektörü depo sorumlusu
    ('udef-gdep0-0000-0000-0000-000000000006', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'giyim_depo', true, 'TR', 'AGENCY_ID', 'Giyim Depo Sorumlusu', 'giyim_depo', 'USER')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ERİŞİM BİLGİLERİ (user_def_access)
-- Şifre: PBKDF2WithHmacSHA1 · 1024 iter · 256-bit
--
-- admin        → admin123
-- kasiyer      → kasiyer123
-- depo         → depo123
-- magaza_admin → magaza123
-- giyim_kasiyer→ giyim123
-- giyim_depo   → giyim456
-- ============================================================
INSERT INTO user_def_access (id, create_time, create_user, last_modified_time, update_user,
                             company_code, access_type, can_login, has_ip_restriction,
                             ip_restriction, is_force_password_change, last_change_time,
                             password_hash, salt_key, user_def_id)
VALUES
    ('uacc-admin-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     'JI1KzWlPRvgcsVO/Y/dR7gDxxDuFlAHbxiQxj7QGjcw=',
     'YWRtaW5zYWx0MTIzNDU2',
     'udef-admin-0000-0000-0000-000000000001'),

    ('uacc-kasiy-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     'bfV/PaJuohhVbz7cLZzThRiawQ/W4o7ohh+qdvvnvc4=',
     'a2FzaXllcnNhbHQxMjM0',
     'udef-kasiy-0000-0000-0000-000000000002'),

    ('uacc-depo0-0000-0000-0000-000000000003', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     'waEXHxvD4c7l7iGYPXbIbzHkS8Z2JM/8D7eQrKSjxrg=',
     'ZGVwb3NhbHQxMjM0NTY3',
     'udef-depo0-0000-0000-0000-000000000003'),

    ('uacc-mgzad-0000-0000-0000-000000000004', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     'Y/p9TrRU1R5JyK63MNVb3d6fVrxxFQJL2NVMjJ4QGtY=',
     'bWFnYXphc2FsdDEyMzQ1',
     'udef-mgzad-0000-0000-0000-000000000004'),

    ('uacc-gkasy-0000-0000-0000-000000000005', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     '5HnDv9SwRQHjg+aDu37NhtSOa3AteGYzfFNVIsB1ipo=',
     'Z2l5aW1zYWx0MTIzNDU2',
     'udef-gkasy-0000-0000-0000-000000000005'),

    ('uacc-gdep0-0000-0000-0000-000000000006', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE1', 'INTERNAL', true, false, false, false, CURRENT_TIMESTAMP,
     'ESsw/Y8pJi1jdeSAIwXfwiewoWPRAvIX/oDtnbmZvyA=',
     'Z2l5aW1kZXBvc2FsdDEy',
     'udef-gdep0-0000-0000-0000-000000000006')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ROL ATAMALARI (user_role)
-- ============================================================
INSERT INTO user_role (id, create_time, create_user, last_modified_time, update_user,
                       company_code, role_def_id, user_def_id)
VALUES
    -- admin → ADMIN rolü
    ('urol-admin-0000-0000-0000-000000000001', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-admin-0000-0000-0000-000000000001', 'udef-admin-0000-0000-0000-000000000001'),

    -- kasiyer → CASHIER rolü
    ('urol-kasiy-0000-0000-0000-000000000002', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-kasiy-0000-0000-0000-000000000002', 'udef-kasiy-0000-0000-0000-000000000002'),

    -- depo → WAREHOUSE rolü
    ('urol-depo0-0000-0000-0000-000000000003', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-depo0-0000-0000-0000-000000000003', 'udef-depo0-0000-0000-0000-000000000003'),

    -- magaza_admin → STORE_MANAGER rolü
    ('urol-mgzad-0000-0000-0000-000000000004', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-mgzyn-0000-0000-0000-000000000004', 'udef-mgzad-0000-0000-0000-000000000004'),

    -- giyim_kasiyer → CASHIER rolü
    ('urol-gkasy-0000-0000-0000-000000000005', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-kasiy-0000-0000-0000-000000000002', 'udef-gkasy-0000-0000-0000-000000000005'),

    -- giyim_depo → WAREHOUSE rolü
    ('urol-gdep0-0000-0000-0000-000000000006', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
     'SEDCORE', 'role-depo0-0000-0000-0000-000000000003', 'udef-gdep0-0000-0000-0000-000000000006')
ON CONFLICT (id) DO NOTHING;
