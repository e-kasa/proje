import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/accounts/providers/accounts_notifiers.dart';
import 'package:project_pos/services/service_locator.dart';

final accountSummaryProvider = StateNotifierProvider.autoDispose<
    AccountSummaryNotifier, AccountSummaryState>(
  (ref) {
    final notifier = AccountSummaryNotifier(ref.read(accountServiceProvider));
    notifier.load();
    return notifier;
  },
);

final overdueTrackingProvider = StateNotifierProvider.autoDispose<
    OverdueTrackingNotifier, OverdueTrackingState>(
  (ref) {
    final notifier = OverdueTrackingNotifier(ref.read(accountServiceProvider));
    notifier.loadAll();
    return notifier;
  },
);

final accountStatementProvider = StateNotifierProvider.autoDispose<
    AccountStatementNotifier, AccountStatementState>(
  (ref) => AccountStatementNotifier(ref.read(accountServiceProvider)),
);
