class MenuCategoryModel {
  final String id;
  final String label;
  final List<MenuModel> menus;

  MenuCategoryModel({
    required this.id,
    required this.label,
    required this.menus,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    final menusList = (json['menus'] as List?)
            ?.map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MenuCategoryModel(
      id: json['categoryId'] as String? ?? json['id'] as String? ?? '',
      label: json['categoryName'] as String? ?? json['label'] as String? ?? '',
      menus: menusList,
    );
  }
}

class MenuModel {
  final String id;
  final String label;
  final String icon;
  final List<MenuItemModel> items;

  MenuModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?)
            ?.map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return MenuModel(
      id: json['menuId'] as String? ?? json['id'] as String? ?? '',
      label: json['menuName'] as String? ?? json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      items: itemsList,
    );
  }
}

class MenuItemModel {
  final String id;
  final String label;
  final String link;

  MenuItemModel({
    required this.id,
    required this.label,
    required this.link,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['itemId'] as String? ?? json['id'] as String? ?? '',
      label: json['itemName'] as String? ?? json['label'] as String? ?? '',
      link: json['itemPath'] as String? ?? json['link'] as String? ?? '',
    );
  }
}
