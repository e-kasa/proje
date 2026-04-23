import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/services/service_locator.dart';
import 'payment_record_modal.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

class AccountSummaryDashboardScreen extends ConsumerStatefulWidget {
  const AccountSummaryDashboardScreen({super.key});

  @override
  ConsumerState<AccountSummaryDashboardScreen> createState() =>
      _AccountSummaryDashboardScreenState();
}

class _AccountSummaryDashboardScreenState
    extends ConsumerState<AccountSummaryDashboardScreen> {
  String Function(String) get t => i18nOf(ref);

  // Arama state
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _accountsLoaded = false;

  Map<String, dynamic>? get _summary => ref.watch(accountSummaryProvider).summary;
  List<Map<String, dynamic>> get _overdueList =>
      ref.watch(accountSummaryProvider).overdueList;
  bool get _loading => ref.watch(accountSummaryProvider).isLoading;
  String? get _error => ref.watch(accountSummaryProvider).error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAccounts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() =>
      ref.read(accountSummaryProvider.notifier).load();

  Future<void> _loadAccounts() async {
    try {
      final results = await Future.wait([
        ref.read(customerServiceProvider).getCustomers(),
        ref.read(supplierServiceProvider).getSuppliers(),
      ]);
      if (!mounted) return;
      setState(() {
        _customers = results[0];
        _suppliers = results[1];
        _accountsLoaded = true;
      });
    } catch (_) {
      // Sessiz başarısızlık — arama özelliği opsiyonel, ana akış engellenmesin
    }
  }

  List<_AccountHit> _searchResults() {
    if (_query.length < 2) return const [];
    final q = _query.toLowerCase();
    final hits = <_AccountHit>[];
    for (final c in _customers) {
      final name = (c['name'] ?? '').toString();
      if (name.toLowerCase().contains(q)) {
        hits.add(_AccountHit(
          id: c['id']?.toString() ?? '',
          name: name,
          type: 'CUSTOMER',
        ));
      }
    }
    for (final s in _suppliers) {
      final name = (s['name'] ?? '').toString();
      if (name.toLowerCase().contains(q)) {
        hits.add(_AccountHit(
          id: s['id']?.toString() ?? '',
          name: name,
          type: 'SUPPLIER',
        ));
      }
    }
    return hits.take(20).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('accounts.title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
            tooltip: t('common.refresh'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildError() {
    return AppEmptyState.error(
      title: t('common.error'),
      description: _error ?? '',
      actionText: t('common.refresh'),
      onAction: _loadData,
    );
  }

  Widget _buildContent() {
    final isSearching = _query.length >= 2;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: AppConstants.pagePadding,
          child: AppSearchInput(
            controller: _searchCtrl,
            hint: t('accounts.search_account'),
            onChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: AppConstants.pagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: isSearching
                ? _buildSearchView()
                : _buildDashboardView(),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDashboardView() {
    return [
      _sectionHeader(t('accounts.summary_section'), Icons.dashboard_outlined),
      const SizedBox(height: 12),
      _buildStatGrid(),
      const SizedBox(height: 24),
      _sectionHeader(t('accounts.quick_actions'), Icons.bolt_outlined),
      const SizedBox(height: 12),
      _buildQuickActions(),
      const SizedBox(height: 24),
      _buildOverdueSection(),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildSearchView() {
    final hits = _searchResults();
    if (!_accountsLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (hits.isEmpty) {
      return [
        const SizedBox(height: 32),
        AppEmptyState.search(
          title: t('accounts.no_search_results'),
          description: '',
        ),
      ];
    }
    return [
      _sectionHeader(
        '${t('accounts.search_results')} (${hits.length})',
        Icons.search,
      ),
      const SizedBox(height: 12),
      ...hits.map(_searchResultCard),
    ];
  }

  Widget _searchResultCard(_AccountHit hit) {
    final isCustomer = hit.type == 'CUSTOMER';
    final accent = isCustomer ? AppColors.info : AppColors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => context.push(
          '/accounts/statement',
          extra: StatementArgs(
            accountType: hit.type,
            accountId: hit.id,
            accountName: hit.name,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              child: Icon(
                isCustomer ? Icons.person_outline : Icons.business_outlined,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hit.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCustomer
                        ? t('accounts.customer_label')
                        : t('accounts.supplier_label'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, {Widget? action}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatGrid() {
    final totalReceivable =
        (_summary?['totalCustomerReceivable'] ?? 0).toDouble();
    final totalPayable = (_summary?['totalSupplierPayable'] ?? 0).toDouble();
    final overdueAmount = (_summary?['totalOverdueAmount'] ?? 0).toDouble();
    final totalTransactions = (_summary?['totalTransactionCount'] ?? 0);

    final cards = [
      _statCard(
        label: t('accounts.total_customer_receivable'),
        value: appCurrencyFmt.format(totalReceivable),
        icon: Icons.people_alt_outlined,
        color: AppColors.success,
      ),
      _statCard(
        label: t('accounts.total_supplier_payable'),
        value: appCurrencyFmt.format(totalPayable),
        icon: Icons.business_outlined,
        color: AppColors.warning,
      ),
      _statCard(
        label: t('accounts.overdue'),
        value: appCurrencyFmt.format(overdueAmount),
        icon: Icons.warning_amber_rounded,
        color: AppColors.danger,
      ),
      _statCard(
        label: t('accounts.total_transactions'),
        value: totalTransactions.toString(),
        icon: Icons.swap_horiz_rounded,
        color: AppColors.teal,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: < 600px → 2 kolon, ≥ 600px → 4 kolon (tek sıra)
        // Sabit kart yüksekliği (110px) kullan; geniş ekranda kart büyümesin
        final isWide = constraints.maxWidth >= 600;
        final columns = isWide ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((c) => SizedBox(width: itemWidth, height: 110, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: AppButton.outline(
            text: t('accounts.transactions'),
            icon: Icons.receipt_long_outlined,
            onPressed: () async {
              final result = await AccountSelectDialog.show(
                context,
                loadCustomers: () =>
                    ref.read(customerServiceProvider).getCustomers(),
                loadSuppliers: () =>
                    ref.read(supplierServiceProvider).getSuppliers(),
              );
              if (result != null && mounted) {
                final args = StatementArgs.from(result);
                if (args != null) {
                  context.push('/accounts/statement', extra: args);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton.outline(
            text: t('accounts.overdue'),
            icon: Icons.schedule,
            onPressed: () => context.push('/accounts/overdue'),
          ),
        ),
      ],
    );
  }


  Widget _buildOverdueSection() {
    final top5 = _overdueList.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          t('accounts.overdue'),
          Icons.warning_amber_rounded,
          action: _overdueList.length > 5
              ? AppButton.outline(
                  text: t('common.all'),
                  size: ButtonSize.small,
                  onPressed: () => context.push('/accounts/overdue'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (top5.isEmpty)
          AppEmptyState.noData(
            title: t('accounts.no_overdue'),
            description: '',
          )
        else
          ...top5.map(_overdueCard),
      ],
    );
  }

  Widget _overdueCard(Map<String, dynamic> item) {
    final accountName = item['accountName']?.toString() ?? '-';
    final accountType = item['accountType']?.toString() ?? '';
    final isCustomer = accountType == 'CUSTOMER';
    final amount = (item['debitAmount'] ?? 0).toDouble();
    final dueDate = shortDateString(item['dueDate']?.toString());
    final accentColor = isCustomer ? AppColors.info : AppColors.orange;
    final accountId = item['accountId']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: accountId.isEmpty
            ? null
            : () => context.push(
                  '/accounts/statement',
                  extra: StatementArgs(
                    accountType: accountType,
                    accountId: accountId,
                    accountName: accountName,
                  ),
                ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: AppConstants.borderRadiusSmall,
              ),
              child: Icon(
                isCustomer ? Icons.person_outline : Icons.business_outlined,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: AppConstants.borderRadiusSmall,
                        ),
                        child: Text(
                          isCustomer
                              ? t('accounts.customer_label')
                              : t('accounts.supplier_label'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dueDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              appCurrencyFmt.format(amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountHit {
  final String id;
  final String name;
  final String type; // 'CUSTOMER' | 'SUPPLIER'
  const _AccountHit({required this.id, required this.name, required this.type});
}
