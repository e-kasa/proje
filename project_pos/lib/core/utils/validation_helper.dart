/// Form Validation Helper - Tutarlı validasyon mesajları
class ValidationHelper {
  // Required field validation
  static String? required(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  // Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi gereklidir';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  // Phone number validation (Turkish format)
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gereklidir';
    }

    // Remove spaces, dashes, parentheses
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with +90 or 0 and has 10 digits
    final phoneRegex = RegExp(r'^(\+90|0)?5\d{9}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Geçerli bir telefon numarası girin (örn: 0555 123 4567)';
    }

    return null;
  }

  // Number validation
  static String? number(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }

    if (double.tryParse(value.trim()) == null) {
      return '$fieldName sayı olmalıdır';
    }

    return null;
  }

  // Integer validation
  static String? integer(String? value, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }

    if (int.tryParse(value.trim()) == null) {
      return '$fieldName tam sayı olmalıdır';
    }

    return null;
  }

  // Positive number validation
  static String? positiveNumber(String? value, {String fieldName = 'Bu alan'}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;

    if (double.parse(value!.trim()) <= 0) {
      return '$fieldName pozitif bir sayı olmalıdır';
    }

    return null;
  }

  // Min length validation
  static String? minLength(String? value, int minLength, {String fieldName = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }

    if (value.trim().length < minLength) {
      return '$fieldName en az $minLength karakter olmalıdır';
    }

    return null;
  }

  // Max length validation
  static String? maxLength(String? value, int maxLength, {String fieldName = 'Bu alan'}) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olmalıdır';
    }

    return null;
  }

  // Range validation (for numbers)
  static String? range(
    String? value,
    double min,
    double max, {
    String fieldName = 'Bu alan',
  }) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;

    final numValue = double.parse(value!.trim());

    if (numValue < min || numValue > max) {
      return '$fieldName $min ile $max arasında olmalıdır';
    }

    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }

    return null;
  }

  // Password confirmation validation
  static String? passwordConfirmation(String? value, String? password) {
    if (value == null || value.trim().isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  // Tax ID (Vergi No) validation (Turkey)
  static String? taxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vergi numarası gereklidir';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.length != 10 && cleaned.length != 11) {
      return 'Vergi numarası 10 veya 11 haneli olmalıdır';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Vergi numarası sadece rakam içermelidir';
    }

    return null;
  }

  // IBAN validation (Turkey)
  static String? iban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IBAN gereklidir';
    }

    final cleaned = value.replaceAll(RegExp(r'\s'), '').toUpperCase();

    if (!cleaned.startsWith('TR')) {
      return 'IBAN "TR" ile başlamalıdır';
    }

    if (cleaned.length != 26) {
      return 'IBAN 26 karakter olmalıdır';
    }

    return null;
  }

  // URL validation
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL optional olabilir
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Geçerli bir URL girin';
    }

    return null;
  }

  // Barcode validation
  static String? barcode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Barkod gereklidir';
    }

    // EAN-13 (13 digits) or EAN-8 (8 digits) or UPC (12 digits)
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (![8, 12, 13].contains(cleaned.length)) {
      return 'Barkod 8, 12 veya 13 haneli olmalıdır';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Barkod sadece rakam içermelidir';
    }

    return null;
  }

  // SKU validation
  static String? sku(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'SKU gereklidir';
    }

    // SKU can be alphanumeric with dashes and underscores
    if (!RegExp(r'^[A-Z0-9\-_]+$').hasMatch(value.trim().toUpperCase())) {
      return 'SKU sadece harf, rakam, tire ve alt çizgi içerebilir';
    }

    return null;
  }

  // Percentage validation (0-100)
  static String? percentage(String? value, {String fieldName = 'Bu alan'}) {
    final numberError = number(value, fieldName: fieldName);
    if (numberError != null) return numberError;

    final numValue = double.parse(value!.trim());

    if (numValue < 0 || numValue > 100) {
      return '$fieldName 0 ile 100 arasında olmalıdır';
    }

    return null;
  }

  // Date validation (yyyy-MM-dd format)
  static String? date(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tarih gereklidir';
    }

    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return 'Geçerli bir tarih girin (YYYY-MM-DD)';
    }
  }

  // Time validation (HH:mm format)
  static String? time(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Saat gereklidir';
    }

    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');

    if (!timeRegex.hasMatch(value.trim())) {
      return 'Geçerli bir saat girin (HH:MM)';
    }

    return null;
  }

  // Composite validator - combines multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  // Optional validator - makes a validator optional
  static String? Function(String?) optional(String? Function(String?) validator) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return validator(value);
    };
  }
}
