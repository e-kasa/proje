class User {
  final String id;
  final String username;
  final String displayName;
  final String selectedCompanyCode;
  final String languageVal;
  final List<String> roles;
  final String? email;

  /// Backend'den gelen sektör kodu: "AUTO_PARTS", "TECHNOLOGY", "FOOTWEAR", "GENERAL"
  /// JWT payload'unda veya company-settings endpoint'inden okunur.
  final String? sectorType;

  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.selectedCompanyCode = '',
    this.languageVal = 'TR',
    this.roles = const [],
    this.email,
    this.sectorType,
  });

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? selectedCompanyCode,
    String? languageVal,
    List<String>? roles,
    String? email,
    String? sectorType,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      selectedCompanyCode: selectedCompanyCode ?? this.selectedCompanyCode,
      languageVal: languageVal ?? this.languageVal,
      roles: roles ?? this.roles,
      email: email ?? this.email,
      sectorType: sectorType ?? this.sectorType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'selectedCompanyCode': selectedCompanyCode,
        'languageVal': languageVal,
        'roles': roles,
        'email': email,
        'sectorType': sectorType,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        selectedCompanyCode: json['selectedCompanyCode'] as String? ?? '',
        languageVal: json['languageVal'] as String? ?? 'TR',
        roles: (json['roles'] as List?)?.cast<String>() ?? [],
        email: json['email'] as String?,
        sectorType: json['sectorType'] as String? ??
            json['companySectorType'] as String? ??
            json['sector'] as String?,
      );
}
