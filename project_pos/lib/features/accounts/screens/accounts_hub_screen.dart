import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/features/accounts/di/accounts_di.dart';
import 'package:project_pos/features/accounts/models/statement_args.dart';
import 'package:project_pos/features/accounts/providers/accounts_list_provider.dart';
import 'package:project_pos/features/accounts/providers/selected_account_provider.dart';
import 'package:project_pos/features/accounts/widgets/accounts_list_panel.dart';
import 'package:project_pos/features/accounts/widgets/accounts_summary_bar.dart';
import 'package:project_pos/features/accounts/widgets/statement_detail_panel.dart';
import 'package:project_pos/features/finance/di/finance_di.dart';

/// Cari Hesaplar — Master-Detail Hub.
///
/// Geniş ekran (≥800px): solda liste paneli, sağda ekstre detay paneli.
/// Dar ekran (<800px): liste full screen, satır tıklayınca detail push.
class AccountsHubScreen extends ConsumerStatefulWidget {
  const AccountsHubScreen({super.key});

  @override
  ConsumerState<AccountsHubScreen> createState() => _AccountsHubScreenState();
}

class _AccountsHubScreenState extends ConsumerState<AccountsHubScreen> {
  static const double _wideBreakpoint = 800;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(accountSummaryProvider.notifier).load();
      ref.read(paymentListProvider.notifier).load();
      // Liste, summary'den overdue ID'leri okur, sonra yüklenir
      ref.read(accountsListProvider.notifier).load();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(accountSummaryProvider.notifier).load(),
      ref.read(paymentListProvider.notifier).load(),
    ]);
    await ref.read(accountsListProvider.notifier).load();
    if (ref.read(selectedAccountProvider) != null) {
      await ref.read(accountStatementProvider.notifier).load();
    }
  }

  void _selectFromList(StatementArgs args, {required bool isWide}) {
    ref.read(selectedAccountProvider.notifier).state = args;
    ref.read(accountStatementProvider.notifier).setAccount(
          accountType: args.accountType,
          accountId: args.accountId,
          accountName: args.accountName,
        );
    if (!isWide) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const _AccountDetailPage(),
        ),
      ).then((_) {
        // Detail kapanınca seçimi temizle (yeni cari seçilebilsin)
        ref.read(selectedAccountProvider.notifier).state = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final selectedId = ref.watch(selectedAccountProvider)?.accountId;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: t('accounts.hub_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: t('common.refresh'),
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: LayoutBuilder(
        builder: (ctx, c) {
          final isWide = c.maxWidth >= _wideBreakpoint;
          return Column(
            children: [
              const AccountsSummaryBar(),
              Container(color: AppColors.border, height: 1),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          SizedBox(
                            width: 360,
                            child: AccountsListPanel(
                              selectedId: selectedId,
                              onSelect: (a) =>
                                  _selectFromList(a, isWide: true),
                            ),
                          ),
                          Container(width: 1, color: AppColors.border),
                          const Expanded(child: StatementDetailPanel()),
                        ],
                      )
                    : AccountsListPanel(
                        selectedId: selectedId,
                        onSelect: (a) => _selectFromList(a, isWide: false),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mobile push edilen detay sayfası (dar ekran için).
class _AccountDetailPage extends StatelessWidget {
  const _AccountDetailPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: StatementDetailPanel(showBackButton: true),
      ),
    );
  }
}
