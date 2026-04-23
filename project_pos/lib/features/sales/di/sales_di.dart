import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/sales/providers/sale_list_notifier.dart';
import 'package:project_pos/services/service_locator.dart';

final saleListProvider =
    StateNotifierProvider.autoDispose<SaleListNotifier, SaleListState>(
  (ref) => SaleListNotifier(ref.read(salesServiceProvider)),
);
