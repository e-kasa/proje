import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/theme/app_constants.dart';
import 'package:project_pos/core/utils/formatters.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_provider.dart';
import 'package:project_pos/features/accounts/providers/accounts_notifiers.dart';
import 'package:project_pos/features/accounts/providers/customer_open_sales_provider.dart';
import 'package:project_pos/features/accounts/providers/selected_account_provider.dart';
import 'package:project_pos/features/accounts/providers/selected_sale_provider.dart';
import 'package:project_pos/features/accounts/screens/payment_record_modal.dart';
import 'package:project_pos/features/accounts/services/statement_pdf_service.dart';
import 'package:project_pos/features/accounts/widgets/account_audit_timeline.dart';
import 'package:project_pos/features/accounts/widgets/account_edit_form.dart';
import 'package:project_pos/features/accounts/widgets/accounts_error_view.dart';
import 'package:project_pos/features/finance/di/finance_di.dart';
import 'package:project_pos/services/service_locator.dart';

/// Hub'ın sağ paneli — seçili cariye ait ekstre.
/// Boş durumda placeholder gösterir.
class StatementDetailPanel extends ConsumerWidget {
  /// Mobile push akışı için: geri butonu göstermek istiyor muyuz?
  final bool showBackButton;
  const StatementDetailPanel({super.key, this.showBackButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final selected = ref.watch(selectedAccountProvider);
    final st = ref.watch(accountStatementProvider);

    if (selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: AppEmptyState.noData(
            title: t('accounts.statement_select_prompt'),
            description: t('accounts.statement_select_hint'),
          ),
        ),
      );
    }

    if (st.isLoading) return const Center(child: CircularProgressIndicator());
    // Sprint 8 hot-fix WP2 — ErrorView (I2 düzeltmesi)
    if (st.error != null) {
      return AccountsErrorView(
        error: st.error!,
        message: t('common.error'),
        onRetry: () => ref.read(accountStatementProvider.notifier).load(),
      );
    }

    final s = st.statement;
    // Sprint 11h — selected var ama statement henüz null = yüklenme bekleniyor.
    // Eski davranış SizedBox.shrink() boş sayfa gösteriyordu (autoDispose race:
    // selectedAccountProvider kalıcı, accountStatementProvider re-mount'ta fresh).
    // Tetikleyici durum: hub'a remount + selected stale + statement henüz fetch olmadı.
    if (s == null) {
      // Lazy load: hasAccount false ise notifier'a yeniden setAccount uygula.
      if (!st.hasAccount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(accountStatementProvider.notifier).setAccount(
                accountType: selected.accountType,
                accountId: selected.accountId,
                accountName: selected.accountName,
              );
        });
      } else if (st.error == null) {
        // hasAccount true ama statement henüz yüklenmemiş → ilk fetch tetikle.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(accountStatementProvider.notifier).load();
        });
      }
      return const Center(child: CircularProgressIndicator());
    }

    final opening = (s['openingBalance'] ?? 0).toDouble();
    final closing = (s['closingBalance'] ?? 0).toDouble();
    final debit = (s['totalDebit'] ?? 0).toDouble();
    final credit = (s['totalCredit'] ?? 0).toDouble();
    // Sprint 8 hot-fix D3 — denormalize currentBalance (CustomerAccount.currentBalance)
    // Backend yoksa fallback: closingBalance. closing != currentBalance ise drift sinyali.
    final currentBalance = (s['currentBalance'] ?? closing).toDouble();
    final hasDrift = (currentBalance - closing).abs() > 0.01;
    final allTransactions =
        List<Map<String, dynamic>>.from(s['transactions'] ?? []);
    final visible = st.visibleTransactions;
    final groups = _groupTransactions(visible, t);
    // Sprint 11d — ekstrede görünen distinct plakalar; boşsa plaka filter bar
    // gizlenir (parçacı sektörü dışı veya hiç plaka atanmamış).
    final plates = st.availablePlates;
    final dateRange = DateTimeRange(start: st.startDate, end: st.endDate);
    final padding = AppConstants.pagePadding;

    return RefreshIndicator(
      onRefresh: () => ref.read(accountStatementProvider.notifier).load(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                padding.left, padding.top, padding.right, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _Header(
                  account: selected,
                  dateRange: dateRange,
                  showBackButton: showBackButton,
                  onBack: () {
                    ref.read(selectedAccountProvider.notifier).state = null;
                    if (showBackButton) Navigator.pop(context);
                  },
                  onPickRange: () => _pickDateRange(context, ref, dateRange),
                  onEdit: () => _handleEdit(context, ref, selected),
                  onPayment: () => _handlePayment(context, ref, selected),
                  onHistory: () => AccountAuditTimeline.show(
                    context,
                    accountType: selected.accountType,
                    accountId: selected.accountId,
                    accountName: selected.accountName,
                  ),
                  onPdf: () => StatementPdfService.show(
                    accountName: selected.accountName,
                    accountType: selected.accountType,
                    startDate: dateRange.start,
                    endDate: dateRange.end,
                    openingBalance: opening,
                    closingBalance: closing,
                    totalDebit: debit,
                    totalCredit: credit,
                    transactions: allTransactions,
                  ),
                ),
                const SizedBox(height: 12),
                _PeriodActivityBlock(
                  opening: opening,
                  debit: debit,
                  credit: credit,
                  closing: closing,
                  accountType: selected.accountType,
                ),
                const SizedBox(height: 12),
                _CurrentStatusBlock(
                  currentBalance: currentBalance,
                  closing: closing,
                  hasDrift: hasDrift,
                  creditLimit: (s['creditLimit'] ?? 0).toDouble(),
                  availableCredit: (s['availableCreditLimit'] ?? 0).toDouble(),
                  exceeded: s['isCreditLimitExceeded'] == true,
                  onReconcile: () =>
                      _handleReconcile(context, ref, selected),
                ),
                const SizedBox(height: 12),
                _TxFilterBar(
                  current: st.filter,
                  onSelect: (f) =>
                      ref.read(accountStatementProvider.notifier).setFilter(f),
                ),
                if (plates.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _TxVehiclePlateBar(
                    plates: plates,
                    selected: st.vehiclePlate,
                    onSelect: (p) => ref
                        .read(accountStatementProvider.notifier)
                        .setVehiclePlate(p),
                  ),
                  if (st.vehiclePlate != null &&
                      selected.accountType == 'CUSTOMER') ...[
                    const SizedBox(height: 8),
                    _VehiclePlateSummaryBand(
                      customerId: selected.accountId,
                      plate: st.vehiclePlate!,
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(t('accounts.transactions'),
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('${visible.length}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  AppEmptyState.noData(
                      title: t('common.no_records'), description: ''),
              ]),
            ),
          ),
          for (final group in groups) ...[
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: padding.left),
              sliver: SliverToBoxAdapter(
                child: _TxGroupHeader(
                  label: group.label,
                  count: group.rows.length,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: padding.left),
              sliver: SliverList.builder(
                itemCount: group.rows.length,
                itemBuilder: (_, i) => _TxRow(tx: group.rows[i]),
              ),
            ),
          ],
          SliverPadding(padding: EdgeInsets.only(bottom: padding.bottom)),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(
      BuildContext context, WidgetRef ref, DateTimeRange current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked != null) {
      ref
          .read(accountStatementProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _handlePayment(
      BuildContext context, WidgetRef ref, StatementArgs account) async {
    final isCustomer = account.accountType == 'CUSTOMER';
    final result = await PaymentRecordModal.show(
      context,
      isCustomer: isCustomer,
      accountName: account.accountName,
      // Sprint 7 — alışveriş bazlı ödeme picker'ı için (sadece müşteri tarafı)
      customerId: isCustomer ? account.accountId : null,
    );
    if (result == null || !context.mounted) return;

    final payload = <String, dynamic>{
      'amount': result['amount'],
      'paymentType': result['paymentType'],
      if (isCustomer)
        'customerId': account.accountId
      else
        'supplierId': account.accountId,
      if (result['bankName'] != null) 'bankName': result['bankName'],
      if (result['referenceNo'] != null)
        'referenceNumber': result['referenceNo'],
      if (result['description'] != null) 'description': result['description'],
      // Sprint 7 — backend Sale-Payment many-to-many allocation
      if (result['allocations'] != null) 'allocations': result['allocations'],
      // Geriye uyum: backend deprecated saleId field'ı hâlâ kabul ediyor
      if (result['saleId'] != null) 'saleId': result['saleId'],
    };

    try {
      await ref.read(paymentServiceProvider).createPayment(payload);
      if (!context.mounted) return;
      AppToast.success(context, i18nOf(ref)('ac.payment_saved'));
      // Sprint 8 hot-fix (Bug B): autoDispose accountsListProvider için race
      // condition'ı önlemek üzere explicit invalidate. notifier.load() yerine
      // ref.invalidate() — provider yeniden subscribe olduğunda fresh state
      // ile loadFirst() çalışır.
      ref.invalidate(accountsListProvider);
      await Future.wait([
        ref.read(accountStatementProvider.notifier).load(),
        ref.read(accountSummaryProvider.notifier).load(),
        ref.read(paymentListProvider.notifier).load(),
      ]);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, '${i18nOf(ref)('common.error')}: $e');
    }
  }

  Future<void> _handleReconcile(
      BuildContext context, WidgetRef ref, StatementArgs account) async {
    final t = i18nOf(ref);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('accounts.reconcile_action')),
        content: Text('${account.accountName}\n\n${t('accounts.reconcile_confirm')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('accounts.reconcile_action')),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      final result = await ref.read(accountServiceProvider).reconcileAccount(
            accountType: account.accountType,
            accountId: account.accountId,
          );
      if (!context.mounted) return;
      final drift = (result['drift'] ?? 0).toDouble();
      AppToast.success(
        context,
        '${t('accounts.reconcile_success')} (Δ ${appCurrencyFmt.format(drift)})',
      );
      // _handlePayment ile aynı refresh stratejisi: invalidate + paralel reload
      ref.invalidate(accountsListProvider);
      await Future.wait([
        ref.read(accountStatementProvider.notifier).load(),
        ref.read(accountSummaryProvider.notifier).load(),
      ]);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, '${t('common.error')}: $e');
    }
  }

  Future<void> _handleEdit(
      BuildContext context, WidgetRef ref, StatementArgs account) async {
    // Mevcut cari bilgilerini servisten çek — initialData dolu form için.
    Map<String, dynamic>? data;
    try {
      if (account.accountType == 'CUSTOMER') {
        data = await ref
            .read(customerServiceProvider)
            .getCustomerById(account.accountId);
      } else {
        data = await ref
            .read(supplierServiceProvider)
            .getSupplierById(account.accountId);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, 'Bilgiler alınamadı: $e');
      return;
    }
    if (data == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: AccountEditForm(
              initialType: account.accountType,
              editingId: account.accountId,
              initialData: data,
              onSuccess: () {
                Navigator.pop(sheetCtx);
              },
              onCancel: () => Navigator.pop(sheetCtx),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final StatementArgs account;
  final DateTimeRange dateRange;
  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onPickRange;
  final VoidCallback onPdf;
  final VoidCallback onEdit;
  final VoidCallback onPayment;
  final VoidCallback onHistory;

  const _Header({
    required this.account,
    required this.dateRange,
    required this.showBackButton,
    required this.onBack,
    required this.onPickRange,
    required this.onPdf,
    required this.onEdit,
    required this.onPayment,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isCustomer = account.accountType == 'CUSTOMER';
    final accent = isCustomer ? AppColors.info : AppColors.orange;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppColors.textPrimary),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (showBackButton) const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: Icon(
                  isCustomer
                      ? Icons.person_outline
                      : Icons.business_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.accountName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      isCustomer
                          ? t('accounts.customer_label')
                          : t('accounts.supplier_label'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isCustomer
                      ? Icons.payments_outlined
                      : Icons.outgoing_mail,
                  color: AppColors.success,
                ),
                tooltip: isCustomer
                    ? t('accounts.collect_payment')
                    : t('accounts.record_payment'),
                onPressed: onPayment,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.textPrimary),
                tooltip: t('accounts.edit_info'),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.history,
                    color: AppColors.textPrimary),
                tooltip: 'Değişiklik geçmişi',
                onPressed: onHistory,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.textPrimary),
                tooltip: t('accounts.export_pdf'),
                onPressed: onPdf,
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onPickRange,
            borderRadius: AppConstants.borderRadiusSmall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: AppConstants.borderRadiusSmall,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFmt.format(dateRange.start)}  —  ${dateFmt.format(dateRange.end)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Dönem Hareketi" bloğu — seçili tarih aralığına göre 4 değer.
/// 3. kart accountType'a göre i18n: CUSTOMER → "Toplam Tahsilat",
/// SUPPLIER → "Yapılan Ödeme".
class _PeriodActivityBlock extends ConsumerWidget {
  final double opening, debit, credit, closing;
  final String accountType;
  const _PeriodActivityBlock({
    required this.opening,
    required this.debit,
    required this.credit,
    required this.closing,
    required this.accountType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final isCustomer = accountType == 'CUSTOMER';
    return _SectionShell(
      title: t('accounts.section_period'),
      tileHeight: 92,
      children: [
        _StatTile(
          label: t('accounts.opening_balance'),
          value: appCurrencyFmt.format(opening),
          icon: Icons.flag_outlined,
          color: AppColors.info,
        ),
        _StatTile(
          label: t('accounts.total_debt'),
          value: appCurrencyFmt.format(debit),
          icon: Icons.arrow_upward,
          color: AppColors.danger,
        ),
        _StatTile(
          label: isCustomer
              ? t('accounts.total_collection')
              : t('accounts.total_payment_made'),
          value: appCurrencyFmt.format(credit),
          icon: Icons.arrow_downward,
          color: AppColors.success,
        ),
        _StatTile(
          label: t('accounts.statement_closing'),
          value: appCurrencyFmt.format(closing),
          icon: Icons.assessment_outlined,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

/// "Güncel Durum" bloğu — tarih bağımsız: denormalize bakiye + kredi limiti +
/// drift varsa senkronize butonu. creditLimit==0 ise sadece bakiye gösterilir.
class _CurrentStatusBlock extends ConsumerWidget {
  final double currentBalance, closing, creditLimit, availableCredit;
  final bool hasDrift, exceeded;
  final VoidCallback onReconcile;
  const _CurrentStatusBlock({
    required this.currentBalance,
    required this.closing,
    required this.hasDrift,
    required this.creditLimit,
    required this.availableCredit,
    required this.exceeded,
    required this.onReconcile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final tiles = <Widget>[
      _StatTile(
        label: t('accounts.current_balance'),
        value: appCurrencyFmt.format(currentBalance),
        secondaryValue: hasDrift
            ? '⚠ ${t('accounts.statement_calc')}: ${appCurrencyFmt.format(closing)}'
            : '${t('accounts.statement_closing')}: ${appCurrencyFmt.format(closing)}',
        secondaryValueWarning: hasDrift,
        icon: hasDrift
            ? Icons.warning_amber_rounded
            : Icons.account_balance_outlined,
        color: hasDrift ? AppColors.warning : AppColors.primary,
      ),
      if (creditLimit > 0) ...[
        _StatTile(
          label: t('accounts.credit_limit'),
          value: appCurrencyFmt.format(creditLimit),
          icon: Icons.credit_score,
          color: AppColors.info,
        ),
        _StatTile(
          label: exceeded
              ? t('accounts.credit_limit_exceeded')
              : t('accounts.available_credit'),
          value: appCurrencyFmt.format(availableCredit),
          icon: Icons.account_balance_wallet_outlined,
          color: exceeded ? AppColors.danger : AppColors.success,
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionShell(
          title: t('accounts.section_current'),
          tileHeight: 110,
          children: tiles,
        ),
        if (hasDrift) ...[
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('accounts.drift_explain'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.sync, size: 14),
                  label: Text(t('accounts.reconcile_action')),
                  onPressed: onReconcile,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Section shell — küçük başlık + responsive Wrap. Dönem ve Güncel Durum
/// bloklarının ortak iskeleti.
class _SectionShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double tileHeight;
  const _SectionShell({
    required this.title,
    required this.children,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (ctx, c) {
            final n = children.length;
            if (n == 0) return const SizedBox.shrink();
            final isWide = c.maxWidth >= 600;
            final cols = isWide ? (n >= 4 ? 4 : n) : (n == 1 ? 1 : 2);
            const sp = 10.0;
            final w = (c.maxWidth - sp * (cols - 1)) / cols;
            return Wrap(
              spacing: sp,
              runSpacing: sp,
              children: children
                  .map((c) =>
                      SizedBox(width: w, height: tileHeight, child: c))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  /// Bilgi amaçlı alt metin. Drift olduğunda kapanış uyarısı, normal durumda
  /// "Ekstre Kapanışı: ..." bilgi satırı gibi kullanılır.
  final String? secondaryValue;
  /// true → secondaryValue warning rengiyle (drift uyarısı); false → muted.
  final bool secondaryValueWarning;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    this.secondaryValue,
    this.secondaryValueWarning = false,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (secondaryValue != null) ...[
                const SizedBox(height: 2),
                Text(secondaryValue!,
                    style: TextStyle(
                        fontSize: 9,
                        color: secondaryValueWarning
                            ? AppColors.warning
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TxTypeMeta {
  final IconData icon;
  final Color color;
  final String i18nKey;
  const _TxTypeMeta(this.icon, this.color, this.i18nKey);
}

_TxTypeMeta _txTypeMeta(String? type) {
  switch (type) {
    case 'SALE':
      return const _TxTypeMeta(
          Icons.point_of_sale, AppColors.primary, 'ac.tx_type_sale');
    case 'PURCHASE':
      return const _TxTypeMeta(
          Icons.inventory_2_outlined, AppColors.orange, 'ac.tx_type_purchase');
    case 'PAYMENT':
      return const _TxTypeMeta(
          Icons.payments_outlined, AppColors.success, 'ac.tx_type_payment');
    case 'SUPPLIER_PAYMENT':
      return const _TxTypeMeta(Icons.outgoing_mail, AppColors.success,
          'ac.tx_type_supplier_payment');
    case 'COLLECTION':
      return const _TxTypeMeta(
          Icons.payments_outlined, AppColors.success, 'ac.tx_type_collection');
    case 'RETURN':
      return const _TxTypeMeta(
          Icons.undo, AppColors.warning, 'ac.tx_type_return');
    case 'SUPPLIER_RETURN':
      return const _TxTypeMeta(
          Icons.undo, AppColors.warning, 'ac.tx_type_supplier_return');
    case 'CANCEL':
      return const _TxTypeMeta(
          Icons.cancel_outlined, AppColors.danger, 'ac.tx_type_cancel');
    case 'DISCOUNT':
      return const _TxTypeMeta(
          Icons.discount_outlined, AppColors.info, 'ac.tx_type_discount');
    case 'LATE_FEE':
      return const _TxTypeMeta(Icons.warning_amber_rounded, AppColors.danger,
          'ac.tx_type_late_fee');
    case 'ADJUSTMENT_DEBIT':
      return const _TxTypeMeta(
          Icons.tune, AppColors.danger, 'ac.tx_type_adjustment_debit');
    case 'ADJUSTMENT_CREDIT':
      return const _TxTypeMeta(
          Icons.tune, AppColors.success, 'ac.tx_type_adjustment_credit');
    case 'REFUND':
      return const _TxTypeMeta(
          Icons.keyboard_return, AppColors.warning, 'ac.tx_type_refund');
    default:
      return const _TxTypeMeta(
          Icons.receipt_long, AppColors.textMuted, 'accounts.transactions');
  }
}

class _TxRow extends ConsumerWidget {
  final Map<String, dynamic> tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final date = shortDateString(tx['transactionDate']?.toString());
    final desc = tx['description']?.toString() ?? '-';
    final typeStr = tx['transactionType']?.toString();
    final refNo = tx['referenceNumber']?.toString();
    final debit = (tx['debitAmount'] ?? 0).toDouble();
    final credit = (tx['creditAmount'] ?? 0).toDouble();
    final balance = (tx['runningBalance'] ?? 0).toDouble();
    final isDebit = debit > 0;
    final amountColor = isDebit ? AppColors.danger : AppColors.success;
    final meta = _txTypeMeta(typeStr);
    final hasRef = refNo != null && refNo.isNotEmpty;
    // Sprint 11d — Sale.vehiclePlateSnapshot (parçacı sektör + müşteri satışı).
    final plate = tx['vehiclePlate']?.toString();
    final hasPlate = plate != null && plate.isNotEmpty;
    // Sprint 11f — bağlı Sale.id; varsa tx kart tıklanır → SaleDetailPanel.
    final saleId = tx['saleId']?.toString();
    final isClickable = saleId != null && saleId.isNotEmpty;

    final card = AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.1),
              borderRadius: AppConstants.borderRadiusSmall,
            ),
            child: Icon(meta.icon, color: meta.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t(meta.i18nKey),
                          style: TextStyle(
                              fontSize: 10,
                              color: meta.color,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (hasPlate)
                      AppBadge.info(plate,
                          icon: Icons.directions_car_outlined),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    if (hasRef)
                      Text('• ${t('ac.tx_ref')}: $refNo',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isDebit
                    ? '-${appCurrencyFmt.format(debit)}'
                    : '+${appCurrencyFmt.format(credit)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: amountColor),
              ),
              Text(appCurrencyFmt.format(balance),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: isClickable
          ? Material(
              color: Colors.transparent,
              borderRadius: AppConstants.borderRadiusSmall,
              child: InkWell(
                borderRadius: AppConstants.borderRadiusSmall,
                onTap: () {
                  ref.read(selectedSaleProvider.notifier).state = saleId;
                },
                child: card,
              ),
            )
          : card,
    );
  }
}

// ─── P1: Filter Bar ─────────────────────────────────────────────────────────

class _TxFilterBar extends ConsumerWidget {
  final TxFilter current;
  final ValueChanged<TxFilter> onSelect;
  const _TxFilterBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TxFilter.values.map((f) {
          final selected = f == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                t('ac.tx_filter_${f.name}'),
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: selected,
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              showCheckmark: false,
              onSelected: (_) => onSelect(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Sprint 11d: Plaka Filter Bar ───────────────────────────────────────────

/// Ekstre içinde transaction'lara atanmış plakalar üzerinden filtre.
/// Sadece `availablePlates` non-empty olduğunda görünür (parçacı sektörü +
/// en az 1 satışta plaka snapshot var). null seçim = "tümü".
class _TxVehiclePlateBar extends ConsumerWidget {
  final List<String> plates;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _TxVehiclePlateBar({
    required this.plates,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                t('common.all'),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      selected == null ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: selected == null,
              backgroundColor: Colors.white,
              selectedColor: AppColors.info,
              side: BorderSide(
                color: selected == null ? AppColors.info : AppColors.border,
              ),
              showCheckmark: false,
              onSelected: (_) => onSelect(null),
            ),
          ),
          for (final p in plates)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.directions_car_outlined,
                  size: 14,
                  color: selected == p ? Colors.white : AppColors.info,
                ),
                label: Text(
                  p,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        selected == p ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: selected == p,
                backgroundColor: Colors.white,
                selectedColor: AppColors.info,
                side: BorderSide(
                  color: selected == p ? AppColors.info : AppColors.border,
                ),
                showCheckmark: false,
                onSelected: (_) => onSelect(p),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sprint 11d — seçili plaka için açık satış özeti bandı.
/// AccountsHub ekstresinde plaka chip'inin altında görünür: "X açık satış · Y ₺ kalan".
/// `customerOpenSalesProvider` üzerinden plaka filtreli açık satışları çeker;
/// boşsa kendini gizler. Sadece müşteri tarafında çağırılır.
class _VehiclePlateSummaryBand extends ConsumerWidget {
  final String customerId;
  final String plate;
  const _VehiclePlateSummaryBand({
    required this.customerId,
    required this.plate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = i18nOf(ref);
    final salesAsync = ref.watch(customerOpenSalesProvider(
      CustomerOpenSalesKey(customerId, vehiclePlate: plate),
    ));
    return salesAsync.when(
      loading: () => const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (sales) {
        if (sales.isEmpty) return const SizedBox.shrink();
        final remaining = sales.fold<double>(
          0,
          (a, s) =>
              a + ((s['remainingAmount'] as num?)?.toDouble() ?? 0.0),
        );
        return AppCard(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.directions_car_outlined,
                  size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${sales.length} ${t('accounts.open_sales')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${appCurrencyFmt.format(remaining)} ${t('accounts.sale_remaining')}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── P1: Tarih Grupları ─────────────────────────────────────────────────────

class _TxGroup {
  final String label;
  final List<Map<String, dynamic>> rows;
  _TxGroup(this.label, this.rows);
}

List<_TxGroup> _groupTransactions(
    List<Map<String, dynamic>> txs, String Function(String) t) {
  if (txs.isEmpty) return const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(const Duration(days: 6));
  final monthFmt = DateFormat('MMMM yyyy', 'tr_TR');
  final groups = <String, List<Map<String, dynamic>>>{};
  final order = <String>[];

  for (final tx in txs) {
    final raw = tx['transactionDate']?.toString();
    DateTime? dt;
    if (raw != null && raw.isNotEmpty) {
      dt = DateTime.tryParse(raw);
    }
    final String label;
    if (dt == null) {
      label = '—';
    } else {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (d == today) {
        label = t('ac.tx_group_today');
      } else if (d == yesterday) {
        label = t('ac.tx_group_yesterday');
      } else if (d.isAfter(weekStart) || d == weekStart) {
        label = t('ac.tx_group_this_week');
      } else {
        label = monthFmt.format(dt);
      }
    }
    if (!groups.containsKey(label)) {
      order.add(label);
      groups[label] = [];
    }
    groups[label]!.add(tx);
  }
  return order.map((k) => _TxGroup(k, groups[k]!)).toList();
}

class _TxGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _TxGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
