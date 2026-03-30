package com.towpen.base.db.model.comment;


public final class DBComments {

	private DBComments() {

	}

	public final class Tables {

		private Tables() {
		}
		public static final String TABLE_USER_DEF = "Kullanıcı Tanım(Uygulama kullanıcıları ve Kişisel Kullanıcılar dahil)";
		public static final String TABLE_USER_DEF_COMPANY_AUTH = "Kullanıcının hangi şirketlerin verilerine görebileceği yetki tanımları";
		public static final String TABLE_USER_DEF_COMPANY_AUTH_LOG = "Kullanıcının hangi şirketlerin verilerine görebileceği yetki tanımları log bilgileri";

		public static final String TABLE_AUTHORIZATION_DEF = "Yetki Tanımları";
		public static final String TABLE_COMPANY = "Multitenant Şirket Tanımları";
		public static final String TABLE_ROLE_AUTHORIZATION = "Rol Yetki Eşleştirmeleri";
		public static final String TABLE_MENU = "Menü Tanımları";
		public static final String TABLE_USER_ROLE = "Kullanıcı rol Tanımları";
		public static final String TABLE_ROLE_DEF = "Rol Tanımları";
		public static final String TABLE_USER_DEF_ACCESS = "Kullanıcı Erişim ";
		public static final String TABLE_USER_DEF_PASSWORD_HISTORY = "Kullanıcının parola değişiklik geçmişi";
		public static final String TABLE_COMPANY_PASSWORD_RULES = "Şirket Parola Kuralları";
		public static final String TABLE_USER_DEF_LOGIN_LOG = "Kullanıcının login olmasının detaylı log alt yapısı";
		public static final String TABLE_LOGIN_ATTEMPT = "Kullanıcı Giriş Denemeleri";


	}
	public final class Fields {

		private Fields() {
		}

		public static final String FIELD_ROLE_AUTHORIZATION_AUTHORIZATION_DEF_ID = "Rol yetki eşlemesi yetki id bilgisi";
		public static final String FIELD_ROLE_AUTHORIZATION_ROLE_DEF_ID = "Rol yetki eşlemesi rol id bilgisi";
		public static final String FIELDS_USER_DEF_GENERIC_IDENTIFIER = "Bağlantısız dinamik tablo idsi";
		public static final String FIELDS_USER_DEF_GENERIC_IDENTIFIER_TYPE = "Bağlantısız dinamik tablo id tipi";
		public static final String FIELD_MENU_ACTIVE = "Menü bilgisinin aktif olup olmama durumu";
		public static final String FIELD_MENU_EXTERNAL_LINK = "Menü linki dışarda bir adrese yönlendirme yapıyorsa gideceği adres";
		public static final String FIELD_MENU_ICON = "Menü icon bilgisi";
		public static final String FIELD_MENU_MENU_LINK = "Menünün jsure uygulamasında gideceği adres linki";
		public static final String FIELD_MENU_MENU_TEXT_EN = "Menü ingilizce başlığı";
		public static final String FIELD_MENU_MENU_TEXT_TR = "Menü Türkçe başlığı";
		public static final String FIELD_MENU_MENU_TYPE = "Menü tipi [MENU-> menü, FOLDER -> klasör, EXTERNAL -> harici adresleme]";
		public static final String FIELD_MENU_PARENT_MENU_ID = "Üst menü bilgisi id si";
		public static final String FIELD_MENU_ROW_ORDER_NO = "Menünün sayfada gösterim sıralama bilgisi";
		public static final String FIELD_MENU_TOOLTIP_EN = "Menü üzerine gelindiğinde yazılacak ingilizce text";
		public static final String FIELD_MENU_TOOLTIP_TR = "Menü üzerine gelindiğinde yazılacak Türkçe text";
		public static final String FIELD_AUTHORIZATION_DEF_DESCRIPTION = "Yetki tanımı açıklaması";
		public static final String FIELD_AUTHORIZATION_DEF_IS_ACTIVE = "Yetki tanımı aktiflik durumu";
		public static final String FIELD_AUTHORIZATION_DEF_MENU_ID = "Yetki tanımının bağlı olduğu menü id bilgisi";
		public static final String FIELD_AUTHORIZATION_DEF_NAME = "Yetki tanımı adı";
		public static final String FIELD_AUTHORIZATION_DEF_SHORT_CODE = "Yetki tanımı kısa kodu";
		public static final String FIELD_USER_ROLE_ROLE_DEF_ID = "Rol referans id bilgisi";
		public static final String FIELD_USER_ROLE_USER_DEF_ID = "Kullanıcı referans id bilgisi";
		public static final String FIELD_LOGIN_ATTEMPT_BROWSER = "Oturum açmaya çalışırken kullanılan browser bilgisi";
		public static final String FIELD_LOGIN_ATTEMPT_ERROR_MESSAGE = "Oturum açmaya çalışırken alınan hata mesajı";
		public static final String FIELD_LOGIN_ATTEMPT_IP_ADDRESS = "Oturum açmaya çalışırken gelinen ip adres bilgisi";
		public static final String FIELD_LOGIN_ATTEMPT_IS_LOGIN_SUCCESS = "Oturum açma işlemi başarılı oldu mu bilgisi";
		public static final String FIELD_LOGIN_ATTEMPT_SERVER_NAME = "Oturum açmaya çalışırken işlemin yapıldığı server adı";
		public static final String FIELD_LOGIN_ATTEMPT_USER_NAME = "Oturum açmaya çalışan kullanıcı adı";
		public static final String FIELD_USER_DEF_IS_ACTIVE = "Kullanıcının sisteme login olup olamayacağı bilgisi";
		public static final String FIELD_USER_DEF_LANGUAGE_VAL = "Ekranların ve hata mesajlarının hangi dil seçeneği ile çalışacağı [EN->İngilizce, TR->Türkçe]";
		public static final String FIELD_USER_DEF_USER_DISPLAY_NAME = "Sisteme login olunan kullanıcının görünen ismi (kullanıclarda genellikle ad soyad)";
		public static final String FIELD_USER_DEF_USER_NAME = "Sisteme login olunan kullanıcı adı";
		public static final String FIELD_COMPANY_COMPANY_NAME = "Şirket adı";
		public static final String FIELD_COMPANY_COMPANY_CODE = "Şirket kodu";
		public static final String FIELD_USER_DEF_USER_TYPE = "Kullanıcının tipi [APPLICATION->Sistem kullanıcısı USER->Kişisel User]";
		public static final String FIELD_USER_DEF_ACCESS_ACCESS_TYPE = "Login olacağı sistem bilgisi [LDAP->Ldap,INTERNAL->Jsuredaki login sistemi mekazinması]";
		public static final String FIELD_USER_DEF_ACCESS_CAN_LOGIN = "Kullanıcı uygulamaya giriş yapabilir mi bilgisi";
		public static final String FIELD_USER_DEF_ACCESS_HAS_IP_RESTRICTION = "Kullanıcının IP kısıtlaması var mı bilgisi";
		public static final String FIELD_USER_DEF_ACCESS_IP_RESTRICTION = "IP kısıtlamasına sahip kullanıcının kısıtlı olduğu IP ler ; ile birleştirilmiş halde";
		public static final String FIELD_USER_DEF_ACCESS_IS_FORCE_PASSWORD_CHANGE = "Kullanıcının parolası değiştirilecek mi";
		public static final String FIELD_USER_DEF_ACCESS_LAST_CHANGE_TIME = "Parola en son ne zaman güncellenmiş bilgisi";
		public static final String FIELD_USER_DEF_ACCESS_PASSWORD_HASH = "Parolanın kriptolu hali";
		public static final String FIELD_USER_DEF_ACCESS_SALT_KEY = "Parola kripto anahtarı";
		public static final String FIELD_USER_DEF_ACCESS_USER_DEF_ID = "Kullanıcı id bilgisi";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_COMPANY_ID = "Şirket referans id bilgisi";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_USER_DEF_ID = "Kullanıcı referans id bilgisi";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_LOG_COMPANY_ID = "Şirket referans id bilgisi";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_LOG_PROCESS = "Log tipi [ADD,DELETE]";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_LOG_PROCESS_USER = "İşlem yapan kullanıcıs";
		public static final String FIELD_USER_DEF_COMPANY_AUTH_LOG_USER_DEF_ID = "Kullanıcı referans id bilgisi";
		public static final String FIELD_USER_DEF_LOGIN_LOG_LOGIN_ATTEMPT_ID = "Login deneme tablosundaki eşleşme id bilgisi";
		public static final String FIELD_USER_DEF_LOGIN_LOG_LOGIN_TIME = "Başarılı login olma tarihi";
		public static final String FIELD_USER_DEF_LOGIN_LOG_LOGOUT_TIME = "Başarılı logout tarihi";
		public static final String FIELD_USER_DEF_LOGIN_LOG_USER_DEF_ID = "User_def id bilgisi";
		public static final String FIELD_USER_DEF_PASSWORD_HISTORY_PASSWORD_CHANGE_TIME = "Parola değiştirilme tarihi";
		public static final String FIELD_USER_DEF_PASSWORD_HISTORY_PASSWORD_HASH = "Parolanın şifrelenmiş hali";
		public static final String FIELD_USER_DEF_PASSWORD_HISTORY_SALT_KEY = "Parolanın salt key bilgisi";
		public static final String FIELD_USER_DEF_PASSWORD_HISTORY_USER_DEF_ID = "Parolanın hangi usera ait olduğu id bilgisi";
		public static final String FIELD_USER_DEF_PROPOSAL_FAVORITE_PROPOSAL_FAVORITE_ID = "Favori teklif seçim id bilgisi";
		public static final String FIELD_USER_DEF_PROPOSAL_FAVORITE_PROPOSAL_DATA = "Favori teklif seçim id bilgisi";
		public static final String FIELD_USER_DEF_PROPOSAL_FAVORITE_PROPOSAL_PLAN_CODE = "Favori teklif seçim plan kodu bilgisi";
		public static final String FIELD_USER_DEF_PROPOSAL_FAVORITE_USER_DEF_ID = "User_def id bilgisi";
		public static final String FIELD_COMPANY_MINI_LOGO_ID = "Şirkete ait mini logo id bilgisi";
		public static final String FIELD_COMPANY_PASSWORD_RULES_DIGIT_COUNT = "Parolada hane sayısı";
		public static final String FIELD_COMPANY_PASSWORD_RULES_EXPIRATION_PERIOD = "Parola yenileme periyodu(ay cinsinden)";
		public static final String FIELD_COMPANY_PASSWORD_RULES_LOWER_CASE_CHAR_COUNT = "Parolada bulunacak minimum küçük karakterli hane sayısı";
		public static final String FIELD_COMPANY_PASSWORD_RULES_MAX_LENGTH = "Parola maksimum uzunluğu";
		public static final String FIELD_COMPANY_PASSWORD_RULES_MIN_LENGTH = "Parola minimum uzunluğu";
		public static final String FIELD_COMPANY_PASSWORD_RULES_PASSWORD_DIFFERENT_COUNT = "Yeni parola son kaç adet paroladan farklı olmaldır bilgisi";
		public static final String FIELD_COMPANY_PASSWORD_RULES_SPECIAL_CHARACTER_COUNT = "Parolada bulunacak minimum özel karakterli hane sayısı";
		public static final String FIELD_COMPANY_PASSWORD_RULES_UPPER_CASE_CHAR_COUNT = "Parolada bulunacak minimum büyük karakterli hane sayısı";

		public static final String FIELD_COMPANY_IS_MAIN_COMPANY = "Ürünün temel tanımlı şirketi mi bilgisi";
		public static final String FIELD_COMPANY_TAX_NUMBER = "Kurumun vergi kimlik numarasıdır.";
		public static final String FIELD_COMPANY_TAX_OFFICE = "Kurumun vergi dairedir.";
		public static final String FIELD_COMPANY_LOGO_ID = "Şirkete ait logo id bilgisi";




		public final class SharedFields {

			private SharedFields() {
			}

			public static final String FIELD_SHARED_BASE_ID = "ID";
			public static final String FIELD_SHARED_CREATE_TIME = "Kaydın Oluşturulma Tarihi";
			public static final String FIELD_SHARED_CREATE_USER = "Kaydı Oluşturan Kullanıcının Kullanıcı Kodu";
			public static final String FIELD_SHARED_LAST_MODIFIED_TIME = "Kaydın Son Güncellenme Tarihi";
			public static final String FIELD_SHARED_LAST_MODIFIED_USER = "Kaydı Son Gülleceyen Kullanıcının Kullanıcı Kodu";
			public static final String FIELD_SHARED_COMPANY_CODE = "Kayıdın sahip şirket kodu bilgisi";
			public static final String FIELD_SHARED_VALIDITY_START = "Kaydın geçerlilik başlangıç tarihi";
			public static final String FIELD_SHARED_VALIDITY_END = "Kaydın geçerlilik bitiş tarihi";
			public static final String FIELD_SHARED_TOP_INDICATOR = "Geçerli kayıt bilgisi";
			public static final String FILED_BOOLEAN_TYPE = "[0->Hayır 1->Evet]";
		}

	}
}
