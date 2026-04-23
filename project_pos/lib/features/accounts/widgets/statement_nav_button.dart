import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';

/// AppBar action button: ilgili cariye ait tarihli ekstreyi açar.
/// Hem `CustomerAccountDetailScreen` hem `SupplierAccountDetailScreen`
/// tarafından kullanılır.
class StatementNavButton extends ConsumerWidget {
  final String accountType;
  final String accountId;
  final String accountName;

  const StatementNavButton({
    super.key,
    required this.accountType,
    required this.accountId,
    required this.accountName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return IconButton(
      icon: const Icon(Icons.fact_check_outlined,
          color: AppColors.textPrimary),
      tooltip: t('accounts.detailed_statement'),
      onPressed: () => context.push(
        '/accounts/statement',
        extra: StatementArgs(
          accountType: accountType,
          accountId: accountId,
          accountName: accountName,
        ),
      ),
    );
  }
}
