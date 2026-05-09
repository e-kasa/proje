/// `/accounts/statement` rotasına geçilen tip-safe parametre sınıfı.
///
/// Önceden `Map<String, dynamic>` ile geçildiği için key isimleri (`accountId`
/// vs `id`) tutarsızlığa yol açıyordu. Bu sınıf tek noktadan kontrol sağlar.
class StatementArgs {
  final String accountType; // 'CUSTOMER' | 'SUPPLIER'
  final String accountId;
  final String accountName;

  /// Sprint 11e — AccountsList plaka modunda bir sonuç tıklanınca cari + plaka
  /// birlikte iletilir. Hub `selectedAccountProvider`'ı set ettikten sonra
  /// statement load olunca `accountStatementProvider.notifier.setVehiclePlate`
  /// otomatik çağırılır → ekstre açılır açılmaz plaka filter aktif.
  final String? initialVehiclePlate;

  const StatementArgs({
    required this.accountType,
    required this.accountId,
    required this.accountName,
    this.initialVehiclePlate,
  });

  Map<String, dynamic> toExtra() => {
        'accountType': accountType,
        'accountId': accountId,
        'accountName': accountName,
        if (initialVehiclePlate != null) 'initialVehiclePlate': initialVehiclePlate,
      };

  /// Hem `StatementArgs` hem `Map` (eski çağıranlar) destekler.
  static StatementArgs? from(Object? raw) {
    if (raw is StatementArgs) return raw;
    if (raw is Map) {
      final m = raw.cast<String, dynamic>();
      final type = m['accountType']?.toString();
      final id = m['accountId']?.toString();
      final name = m['accountName']?.toString();
      final plate = m['initialVehiclePlate']?.toString();
      if (type == null || id == null || id.isEmpty) return null;
      return StatementArgs(
        accountType: type,
        accountId: id,
        accountName: name ?? '',
        initialVehiclePlate: (plate != null && plate.isNotEmpty) ? plate : null,
      );
    }
    return null;
  }
}
