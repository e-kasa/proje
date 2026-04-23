/// `/accounts/statement` rotasına geçilen tip-safe parametre sınıfı.
///
/// Önceden `Map<String, dynamic>` ile geçildiği için key isimleri (`accountId`
/// vs `id`) tutarsızlığa yol açıyordu. Bu sınıf tek noktadan kontrol sağlar.
class StatementArgs {
  final String accountType; // 'CUSTOMER' | 'SUPPLIER'
  final String accountId;
  final String accountName;

  const StatementArgs({
    required this.accountType,
    required this.accountId,
    required this.accountName,
  });

  Map<String, dynamic> toExtra() => {
        'accountType': accountType,
        'accountId': accountId,
        'accountName': accountName,
      };

  /// Hem `StatementArgs` hem `Map` (eski çağıranlar) destekler.
  static StatementArgs? from(Object? raw) {
    if (raw is StatementArgs) return raw;
    if (raw is Map) {
      final m = raw.cast<String, dynamic>();
      final type = m['accountType']?.toString();
      final id = m['accountId']?.toString();
      final name = m['accountName']?.toString();
      if (type == null || id == null || id.isEmpty) return null;
      return StatementArgs(
        accountType: type,
        accountId: id,
        accountName: name ?? '',
      );
    }
    return null;
  }
}
