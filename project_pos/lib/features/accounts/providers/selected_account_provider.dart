import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';

/// Hub içinde seçili cari (Ekstre tab'ı için).
/// Üst-arama veya overdue/ödeme satırına tıklayınca set edilir.
final selectedAccountProvider = StateProvider<StatementArgs?>((ref) => null);
