import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/models/bulk_import_models.dart';
import 'package:project_pos/core/widgets/widgets.dart';

/// Stok Güncelleme Modal - CONFLICT durumu için
class UpdateStockModal extends ConsumerStatefulWidget {
  final AnalyzedProduct product;
  final Function(UserDecision) onDecision;

  const UpdateStockModal({
    super.key,
    required this.product,
    required this.onDecision,
  });

  @override
  ConsumerState<UpdateStockModal> createState() => _UpdateStockModalState();
}

class _UpdateStockModalState extends ConsumerState<UpdateStockModal> {
  String Function(String) get t => i18nOf(ref);
  StockUpdateMode _updateMode = StockUpdateMode.ADD;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(text: widget.product.stock.toString());
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _confirm() {
    final stockValue = int.tryParse(_stockController.text) ?? 0;

    if (stockValue <= 0) {
      AppToast.warning(context, 'Lütfen geçerli bir stok miktarı girin'); // TODO: i18n bulk_import.invalid_stock_amount
      return;
    }

    final decision = UserDecision.updateStock(
      tempId: widget.product.tempId,
      productId: widget.product.matchedProduct!.id,
      mode: _updateMode,
      value: stockValue,
    );

    widget.onDecision(decision);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final matched = widget.product.matchedProduct!;
    final currentStock = matched.currentStock;
    final newStock = int.tryParse(_stockController.text) ?? 0;
    final resultStock = _updateMode == StockUpdateMode.ADD ? currentStock + newStock : newStock;

    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory, color: AppColors.warning, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stok Güncelle', // TODO: i18n bulk_import.update_stock_title
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Product Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mevcut Ürün:', style: TextStyle(fontWeight: FontWeight.w600)), // TODO: i18n bulk_import.existing_product
                  const SizedBox(height: 8),
                  Text('İsim: ${matched.name}', style: const TextStyle(fontSize: 13)),
                  Text('SKU: ${matched.sku}', style: const TextStyle(fontSize: 13)),
                  Text('Mevcut Stok: $currentStock adet',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Mevcut Fiyat: ₺${matched.currentBuyPrice} / ₺${matched.currentSellPrice}',
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Update Mode Selection
            const Text('Güncelleme Modu:', style: TextStyle(fontWeight: FontWeight.w600)), // TODO: i18n bulk_import.update_mode
            const SizedBox(height: 12),

            SegmentedButton<StockUpdateMode>(
              segments: const [
                ButtonSegment(
                  value: StockUpdateMode.ADD,
                  label: Text('Ekle'),
                  icon: Icon(Icons.add),
                ),
                ButtonSegment(
                  value: StockUpdateMode.REPLACE,
                  label: Text('Değiştir'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_updateMode},
              onSelectionChanged: (Set<StockUpdateMode> newSelection) {
                setState(() {
                  _updateMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Stock Input
            const Text('Stok Miktarı:', style: TextStyle(fontWeight: FontWeight.w600)), // TODO: i18n bulk_import.stock_amount
            const SizedBox(height: 12),

            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _updateMode == StockUpdateMode.ADD ? 'Eklenecek Miktar' : 'Yeni Stok Miktarı',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2),
                suffixText: 'adet',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Result Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.1),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sonuç Önizleme:', style: TextStyle(fontWeight: FontWeight.w600)), // TODO: i18n bulk_import.result_preview
                        const SizedBox(height: 4),
                        Text(
                          _updateMode == StockUpdateMode.ADD
                              ? '$currentStock + $newStock = $resultStock adet'
                              : '$currentStock → $resultStock adet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'), // TODO: i18n common.cancel
                ),
                const SizedBox(width: 12),
                AppButton.success(

                  text: 'Güncelle', // TODO: i18n common.update

                  icon: Icons.save,
                  onPressed: _confirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}