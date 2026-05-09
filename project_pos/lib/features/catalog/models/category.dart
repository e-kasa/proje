/// Kategori veri modeli.
///
/// Backend `Category` (global pool), `CompanyCategory` (firma seçimi) ve
/// POS chip / wizard payload'ları farklı key isimleri (örn: `id` vs
/// `categoryId`, `name` vs `categoryName`) ile gelebildiği için
/// [Category.fromJson] tüm varyantları normalize eder.
///
/// Migration plan (Sprint 32 #6): bu sınıf yeni — mevcut
/// `Map<String, dynamic>` kullanıcıları kademeli olarak [Category]'ye
/// taşınacak. Geriye dönük uyumluluk için [toMap] eski anahtarları da yazar.
class Category {
  /// Backend UUID — boş string olabilir (henüz kaydedilmemiş kayıtlar için).
  final String id;

  /// Görüntü adı.
  final String name;

  /// SEO/route slug'ı, opsiyonel.
  final String? slug;

  /// Açıklama (opsiyonel).
  final String? description;

  /// Üst kategori UUID — null ise root.
  final String? parentId;

  /// Hiyerarşik path (`/elektronik/telefon`), opsiyonel.
  final String? path;

  /// Hiyerarşi seviyesi: 0 = root, 1 = alt, 2 = alt-alt.
  final int level;

  /// Görüntüleme sırası — küçük olan önce.
  final int sortOrder;

  /// Resim URL'i (opsiyonel).
  final String? imageUrl;

  /// Material icon adı veya ikon kodu (opsiyonel).
  final String? icon;

  /// Backend [ProductStatus] enum string'i — `ACTIVE`, `DRAFT`, `INACTIVE`,
  /// `ARCHIVED`. `null` ise eski API.
  final String? status;

  /// Soft-delete bayrağı.
  final bool isSoftDeleted;

  /// Frontend tarafında kategori "Kategori Tanımla" ekranında firmanın seçili
  /// olup olmadığını işaretler. Backend `getAllCategoriesWithSelection` döner.
  final bool isSelected;

  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.parentId,
    this.path,
    this.level = 0,
    this.sortOrder = 0,
    this.imageUrl,
    this.icon,
    this.status,
    this.isSoftDeleted = false,
    this.isSelected = false,
  });

  /// Backend ham payload'ından oluştur. Hem `Category` (global) hem de
  /// `CompanyCategory` (tenant junction) anahtarlarını destekler — bu sayede
  /// `getMyCategoryList` (`categoryId`/`categoryName`) ve `/api/category`
  /// (`id`/`name`) aynı sınıfa map edilir.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['categoryId'] ?? json['id'] ?? '').toString(),
      name: (json['categoryName'] ?? json['name'] ?? '').toString(),
      slug: json['categorySlug']?.toString() ?? json['slug']?.toString(),
      description: json['description']?.toString(),
      parentId: (json['categoryParentId'] ?? json['parentId'])?.toString(),
      path: (json['categoryPath'] ?? json['path'])?.toString(),
      level: _toInt(json['categoryLevel'] ?? json['level']) ?? 0,
      sortOrder: _toInt(json['displayOrder'] ?? json['sortOrder']) ?? 0,
      imageUrl: (json['categoryImageUrl'] ?? json['imageUrl'])?.toString(),
      icon: (json['categoryIcon'] ?? json['icon'])?.toString(),
      status: (json['categoryStatus'] ?? json['status'])?.toString(),
      isSoftDeleted: json['isSoftDeleted'] == true || json['isDeleted'] == true,
      isSelected: json['isSelected'] == true,
    );
  }

  /// Backend `Category`/`CompanyCategoryResponse` create/update isteklerinde
  /// kullanılan map. `id` boşsa create payload'ı, doluysa update.
  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        if (slug != null) 'slug': slug,
        if (description != null) 'description': description,
        if (parentId != null) 'parentId': parentId,
        if (path != null) 'path': path,
        'level': level,
        'sortOrder': sortOrder,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (icon != null) 'icon': icon,
        if (status != null) 'status': status,
        'isSoftDeleted': isSoftDeleted,
      };

  /// Eski `Map<String, dynamic>` kullanıcılarına hem yeni hem eski anahtarları
  /// içeren bir görünüm. Migrasyon sırasında interim çözüm.
  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': id,
        'name': name,
        'categoryName': name,
        'slug': slug,
        'description': description,
        'parentId': parentId,
        'categoryParentId': parentId,
        'path': path,
        'level': level,
        'categoryLevel': level,
        'sortOrder': sortOrder,
        'displayOrder': sortOrder,
        'imageUrl': imageUrl,
        'icon': icon,
        'status': status,
        'categoryStatus': status,
        'isSoftDeleted': isSoftDeleted,
        'isSelected': isSelected,
      };

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? parentId,
    String? path,
    int? level,
    int? sortOrder,
    String? imageUrl,
    String? icon,
    String? status,
    bool? isSoftDeleted,
    bool? isSelected,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      path: path ?? this.path,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      isSoftDeleted: isSoftDeleted ?? this.isSoftDeleted,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  bool get isActive {
    if (isSoftDeleted) return false;
    final s = status?.toUpperCase();
    if (s == null || s.isEmpty) return true;
    return s == 'ACTIVE';
  }

  bool get isRoot => parentId == null || parentId!.isEmpty;

  @override
  String toString() => 'Category(id=$id, name=$name, level=$level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
