import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/features/catalog/providers/company_category_notifier.dart';
import 'package:project_pos/services/service_locator.dart';

final companyCategoryProvider =
    StateNotifierProvider<CompanyCategoryNotifier, CompanyCategoryState>(
  (ref) => CompanyCategoryNotifier(ref.read(companyCategoryServiceProvider)),
);
