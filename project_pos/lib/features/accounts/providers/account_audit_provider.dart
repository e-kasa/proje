import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/services/service_locator.dart';

/// Sprint 30 — issue P2.6: Cari audit-log family provider.
///
/// Anahtar: `(accountType, accountId)` tuple. AccountsHub bir cari seçtiğinde
/// "Geçmiş" sekmesi `accountAuditHistoryProvider(AuditTarget(...))` ile
/// `FutureProvider` döndürür.
class AuditTarget {
  final String accountType;
  final String accountId;
  const AuditTarget({required this.accountType, required this.accountId});

  @override
  bool operator ==(Object other) =>
      other is AuditTarget &&
      other.accountType == accountType &&
      other.accountId == accountId;

  @override
  int get hashCode => Object.hash(accountType, accountId);
}

final accountAuditHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, AuditTarget>((ref, target) async {
  final service = ref.read(accountServiceProvider);
  return service.getAuditHistory(
    accountType: target.accountType,
    accountId: target.accountId,
  );
});
