import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_constants.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/service_locator.dart';
import 'providers/batch_entry_provider.dart';
import 'models/batch_entry_models.dart';
import 'widgets/batch_header_form.dart';

class BatchProductScreen extends ConsumerStatefulWidget {
  const BatchProductScreen({super.key});

  @override
  ConsumerState<BatchProductScreen> createState() => _BatchProductScreenState();
}

class _BatchProductScreenState extends ConsumerState<BatchProductScreen> {
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final state = ref.read(batchEntryProvider);
    if (state.rows.isEmpty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sayfadan Ayril'),
        content: const Text(
          'Kaydedilmemis veriler var. Cikmak istediginize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cik'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addByBarcode() async {
    final input = _barcodeController.text.trim();
    if (input.isEmpty) return;
    final notifier = ref.read(batchEntryProvider.notifier);
    final msg = await notifier.addByBarcode(input);
    _barcodeController.clear();
    _barcodeFocus.requestFocus();
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _showVatDialog() {
    const vatRates = [0.0, 1.0, 8.0, 10.0, 18.0, 20.0];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('KDV Orani Sec'),
        children: vatRates.map((rate) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(batchEntryProvider.notifier).applyVatToAll(rate);
              Navigator.pop(ctx);
            },
            child: Text('%${rate.toStringAsFixed(0)}'),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showCategoryPicker() async {
    try {
      final categories =
          await ref.read(companyCategoryServiceProvider).getMyCategoryList();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Kategori Sec'),
          children: categories.map((c) {
            final id = c['id']?.toString() ?? '';
            final name = c['name']?.toString() ?? '';
            return SimpleDialogOption(
              onPressed: () {
                ref
                    .read(batchEntryProvider.notifier)
                    .applyCategoryToAll(id, name);
                Navigator.pop(ctx);
              },
              child: Text(name),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategoriler yuklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _showBrandPicker() async {
    try {
      final brands = await ref.read(brandServiceProvider).getActiveBrands();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Marka Sec'),
          children: brands.map((b) {
            final id = b['id']?.toString() ?? '';
            final name = b['name']?.toString() ?? '';
            return SimpleDialogOption(
              onPressed: () {
                ref.read(batchEntryProvider.notifier).applyBrandToAll(id, name);
                Navigator.pop(ctx);
              },
              child: Text(name),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Markalar yuklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(batchEntryProvider.notifier);
    final error = notifier.validateAll();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final state = ref.read(batchEntryProvider);
    final pendingCount = state.rows.where((r) => !r.isSaved).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydet'),
        content: Text('$pendingCount urun kaydedilecek. Onayliyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final result = await notifier.submitAll();
      if (mounted) _showResultDialog(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showResultDialog(BatchSaveResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.errors == 0 ? Icons.check_circle : Icons.warning,
              color: result.errors == 0 ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Sonuc')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.totalProcessed} urun islendi'),
            if (result.newCreated > 0)
              Text('  * ${result.newCreated} yeni urun olusturuldu'),
            if (result.stockUpdated > 0)
              Text('  * ${result.stockUpdated} mevcut urunun stogu guncellendi'),
            if (result.errors > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${result.errors} hata olustu',
                style: const TextStyle(color: AppColors.danger),
              ),
              ...result.errorMessages.take(5).map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        '- $m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(batchEntryProvider.notifier).clearSavedRows();
            },
            child: const Text('Yeni Giris Yap'),
          ),
          if (result.purchaseId != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // context.push('/purchases/${result.purchaseId}');
              },
              child: const Text('Satin Alma Detayi'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchEntryProvider);
    final numberFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '\u20BA',
      decimalDigits: 2,
    );

    return PopScope(
      canPop: state.rows.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppAppBar.standard(
          title: 'Toplu Urun Girisi',
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Toplu Islemler',
              onSelected: (value) {
                switch (value) {
                  case 'vat':
                    _showVatDialog();
                    break;
                  case 'category':
                    _showCategoryPicker();
                    break;
                  case 'brand':
                    _showBrandPicker();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'vat',
                  child: ListTile(
                    leading: Icon(Icons.percent),
                    title: Text('Tumune KDV Uygula'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'category',
                  child: ListTile(
                    leading: Icon(Icons.category),
                    title: Text('Tumune Kategori Uygula'),
                    dense: true,
                  ),
                ),
                PopupMenuItem(
                  value: 'brand',
                  child: ListTile(
                    leading: Icon(Icons.branding_watermark),
                    title: Text('Tumune Marka Uygula'),
                    dense: true,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Temizle',
              onPressed: () {
                ref.read(batchEntryProvider.notifier).clearAll();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const BatchHeaderForm(),
            // Barcode input
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocus,
                      decoration: const InputDecoration(
                        hintText: 'Barkod veya urun adi girin...',
                        prefixIcon: Icon(Icons.qr_code_scanner),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addByBarcode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addByBarcode,
                    icon: const Icon(Icons.search),
                    tooltip: 'Ara',
                  ),
                  const SizedBox(width: 4),
                  IconButton.outlined(
                    onPressed: () {
                      ref.read(batchEntryProvider.notifier).addManualRow();
                    },
                    icon: const Icon(Icons.add),
                    tooltip: 'Manuel Satir Ekle',
                  ),
                ],
              ),
            ),
            // Product list
            Expanded(
              child: state.rows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 64, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Henuz urun eklenmedi',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Barkod okutun veya manuel satir ekleyin',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: state.rows.length,
                      itemBuilder: (context, index) {
                        final row = state.rows[index];
                        return _buildRowCard(row, numberFormat);
                      },
                    ),
            ),
            // Summary bar
            _buildSummaryBar(state, numberFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(BatchEntryRow row, NumberFormat fmt) {
    final statusColor = switch (row.status) {
      RowStatus.newProduct => AppColors.info,
      RowStatus.existing || RowStatus.matched => AppColors.primary,
      RowStatus.saved => AppColors.success,
      RowStatus.error => AppColors.danger,
      RowStatus.saving => AppColors.warning,
    };
    final statusLabel = switch (row.status) {
      RowStatus.newProduct => 'Yeni',
      RowStatus.existing || RowStatus.matched => 'Mevcut',
      RowStatus.saved => 'Kaydedildi',
      RowStatus.error => 'Hata',
      RowStatus.saving => 'Kaydediliyor',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.productName.isNotEmpty
                        ? row.productName
                        : row.barcode.isNotEmpty
                            ? row.barcode
                            : 'Yeni Urun',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => ref
                      .read(batchEntryProvider.notifier)
                      .removeRow(row.id),
                  visualDensity: VisualDensity.compact,
                  color: AppColors.danger,
                ),
              ],
            ),
            if (row.hasError && row.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  row.errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _infoChip('Adet: ${row.quantity}'),
                const SizedBox(width: 8),
                _infoChip('Alis: ${fmt.format(row.purchasePrice)}'),
                const SizedBox(width: 8),
                _infoChip('Satis: ${fmt.format(row.salePrice)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildSummaryBar(BatchEntryState state, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(
                    '${state.totalItems} urun',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Maliyet: ${fmt.format(state.totalCost)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Kar: ${fmt.format(state.totalProfit)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: state.totalProfit >= 0
                          ? AppColors.success
                          : AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: state.isSubmitting || state.rows.isEmpty
                  ? null
                  : _handleSubmit,
              icon: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(state.isSubmitting ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
