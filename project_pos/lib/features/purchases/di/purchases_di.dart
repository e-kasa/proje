import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/purchases/providers/purchase_list_notifier.dart';
import 'package:project_pos/services/service_locator.dart';

final purchaseListProvider =
    StateNotifierProvider.autoDispose<PurchaseListNotifier, PurchaseListState>(
  (ref) => PurchaseListNotifier(ref.read(purchaseServiceProvider)),
);
