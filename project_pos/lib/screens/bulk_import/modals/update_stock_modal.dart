import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/bulk_import_models.dart';

/// Stok Güncelleme Modal - CONFLICT durumu için
class UpdateStockModal extends StatefulWidget {
  final AnalyzedProduct product;
  final Function(UserDecision) onDecision;

  const UpdateStockModal({
    super.key,
    required this.product,
    required this.onDecision,
  });

  @override
  State<UpdateStockModal> createState() => _UpdateStockModalState();
}

class _UpdateStockModalState extends State<UpdateStockModal> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir stok miktarı girin'),
          backgroundColor: AppColors.warning,
        ),
      );
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
                    color: AppColors.warning.withOpacity(0.1),
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
                        'Stok Güncelle',
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
                  const Text('Mevcut Ürün:', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Text('Güncelleme Modu:', style: TextStyle(fontWeight: FontWeight.w600)),
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
            const Text('Stok Miktarı:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    AppColors.success.withOpacity(0.1),
                    AppColors.success.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sonuç Önizleme:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Güncelle'),
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
