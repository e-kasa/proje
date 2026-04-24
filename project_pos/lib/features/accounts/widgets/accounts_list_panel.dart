import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_provider.dart';
import 'package:project_pos/features/accounts/widgets/account_edit_form.dart';

/// Cari listesi paneli — search + filter chips + scrollable liste.
/// `onSelect` ile bir cari seçilince üst (hub) tarafından detail tarafı yüklenir.
class AccountsListPanel extends ConsumerStatefulWidget {
  final void Function(StatementArgs) onSelect;
  final String? selectedId;

  const AccountsListPanel({
    super.key,
    required this.onSelect,
    this.selectedId,
  });

  @override
  ConsumerState<AccountsListPanel> createState() => _AccountsListPanelState();
}

class _AccountsListPanelState extends ConsumerState<AccountsListPanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCreateModal(BuildContext context) async {
    final initialType =
        _defaultTypeForFilter(ref.read(accountsListProvider).filter);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AccountEditForm(
          initialType: initialType,
          onSuccess: () => Navigator.of(ctx).pop(),
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final st = ref.watch(accountsListProvider);
    final notifier = ref.read(accountsListProvider.notifier);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: AppSearchInput(
                    controller: _searchCtrl,
                    hint: t('accounts.search_account'),
                    onChanged: notifier.setQuery,
                    onClear: () {
                      _searchCtrl.clear();
                      notifier.setQuery('');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _NewAccountButton(onTap: () => _openCreateModal(context)),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _chip(t('common.all'), AccountsFilter.all, st.filter),
                _chip(t('accounts.overdue'), AccountsFilter.overdue, st.filter,
                    color: AppColors.danger),
                _chip(t('accounts.customer_label'),
                    AccountsFilter.customer, st.filter,
                    color: AppColors.info),
                _chip(t('accounts.supplier_label'),
                    AccountsFilter.supplier, st.filter,
                    color: AppColors.orange),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildList(st)),
        ],
      ),
    );
  }

  /// Aktif filtreye göre yeni eklenen cari varsayılan tipi — ör. "Müşteri" filtresindeyken
  /// form CUSTOMER ile açılsın.
  String _defaultTypeForFilter(AccountsFilter f) {
    switch (f) {
      case AccountsFilter.supplier:
        return 'SUPPLIER';
      case AccountsFilter.customer:
      case AccountsFilter.all:
      case AccountsFilter.overdue:
        return 'CUSTOMER';
    }
  }

  Widget _chip(String label, AccountsFilter value, AccountsFilter current,
      {Color? color}) {
    final selected = current == value;
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textPrimary)),
        selected: selected,
        backgroundColor: Colors.white,
        selectedColor: c,
        side: BorderSide(color: selected ? c : AppColors.border),
        showCheckmark: false,
        onSelected: (_) =>
            ref.read(accountsListProvider.notifier).setFilter(value),
      ),
    );
  }

  Widget _buildList(AccountsListState st) {
    final t = i18nOf(ref);
    if (st.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (st.error != null) {
      return AppEmptyState.error(
        title: t('common.error'),
        description: st.error ?? '',
        actionText: t('common.refresh'),
        onAction: () => ref.read(accountsListProvider.notifier).load(),
      );
    }
    final items = st.visible;
    if (items.isEmpty) {
      return AppEmptyState.noData(
          title: t('accounts.no_search_results'), description: '');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return _AccountRow(
          item: item,
          isSelected: item.id == widget.selectedId,
          onTap: () => widget.onSelect(StatementArgs(
            accountType: item.type,
            accountId: item.id,
            accountName: item.name,
          )),
        );
      },
    );
  }
}

class _NewAccountButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewAccountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.person_add_alt_1_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final AccountListItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountRow({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCustomer = item.type == 'CUSTOMER';
    final accent = isCustomer ? AppColors.info : AppColors.orange;
    final bg = isSelected ? AppColors.primary.withValues(alpha: 0.08) : null;
    final border = isSelected ? AppColors.primary : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg ?? Colors.white,
        borderRadius: AppConstants.borderRadiusSmall,
        child: InkWell(
          borderRadius: AppConstants.borderRadiusSmall,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppConstants.borderRadiusSmall,
              border: Border.all(
                  color: border, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: Icon(
                    isCustomer
                        ? Icons.person_outline
                        : Icons.business_outlined,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (item.hasOverdue) ...[
                            const Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.danger),
                            const SizedBox(width: 3),
                          ],
                          Text(
                            appCurrencyFmt.format(item.currentBalance),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: item.hasOverdue
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
