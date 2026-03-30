/*insert into role_def (id, create_time, create_user, last_modified_time, update_user, company_code, code, description,
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
        '6d728059-90fb-4753-b295-953c3c5b2035', '6d728059-90fb-4753-b295-953c3c5b2036');*/





select * from user_def_access;
