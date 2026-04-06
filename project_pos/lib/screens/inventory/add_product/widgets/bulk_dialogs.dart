import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/wizard_state.dart';
import '../../core/widgets/widgets.dart';

/// Shows a dialog to apply bulk stock quantity to all variants.
Future<void> showBulkStockDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
}) async {
  if (state.variants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\u26a0\ufe0f Hen\u00fcz varyant olu\u015fturulmam\u0131\u015f!'), backgroundColor: AppColors.warning),
    );
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(children: [Icon(Icons.inventory_2, color: AppColors.info, size: 24), SizedBox(width: 12), Text('Toplu Stok Uygula', style: TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: 'Stok Miktar\u0131', hintText: '100', prefixIcon: const Icon(Icons.inventory_2, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} varyanta uygulanacak', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('\u0130ptal')),
        ElevatedButton.icon(onPressed: () { final qty = int.tryParse(controller.text); if (qty != null && qty >= 0) Navigator.pop(context, qty); }, icon: const Icon(Icons.check, size: 18), label: const Text('Uygula'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.info)),
      ],
    ),
  );
  if (result != null) {
    for (var variant in state.variants) {
      if (variant.inventory == null) {
        variant.inventory = InventoryInfo(warehouseCode: state.selectedWarehouses.isNotEmpty ? state.selectedWarehouses.first : 'WH-001', physicalQuantity: result);
      } else {
        variant.inventory!.physicalQuantity = result;
      }
    }
    onChanged();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u2705 ${state.variants.length} varyanta $result adet stok uyguland\u0131!'), backgroundColor: AppColors.success));
  }
}

/// Shows a dialog to apply bulk purchase price to all variants.
Future<void> showBulkPurchasePriceDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
}) async {
  if (state.variants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('\u26a0\ufe0f Hen\u00fcz varyant olu\u015fturulmam\u0131\u015f!'), backgroundColor: AppColors.warning));
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(children: [Icon(Icons.attach_money, color: AppColors.danger, size: 24), SizedBox(width: 12), Text('Toplu Al\u0131\u015f Fiyat\u0131', style: TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: 'Al\u0131\u015f Fiyat\u0131', hintText: '100.00', prefixText: '\u20ba ', prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppColors.danger), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} varyanta uygulanacak', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('\u0130ptal')),
        ElevatedButton.icon(onPressed: () { final price = double.tryParse(controller.text); if (price != null && price >= 0) Navigator.pop(context, price); }, icon: const Icon(Icons.check, size: 18), label: const Text('Uygula'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger)),
      ],
    ),
  );
  if (result != null) {
    for (var variant in state.variants) { variant.purchasePrice = result; }
    onChanged();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u2705 ${state.variants.length} varyanta \u20ba${result.toStringAsFixed(2)} al\u0131\u015f fiyat\u0131 uyguland\u0131!'), backgroundColor: AppColors.success));
  }
}

/// Shows a dialog to apply bulk sale price to all variants.
Future<void> showBulkSalePriceDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
}) async {
  if (state.variants.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('\u26a0\ufe0f Hen\u00fcz varyant olu\u015fturulmam\u0131\u015f!'), backgroundColor: AppColors.warning));
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(children: [Icon(Icons.sell, color: AppColors.success, size: 24), SizedBox(width: 12), Text('Toplu Sat\u0131\u015f Fiyat\u0131', style: TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: 'Sat\u0131\u015f Fiyat\u0131', hintText: '150.00', prefixText: '\u20ba ', prefixIcon: const Icon(Icons.sell, size: 20, color: AppColors.success), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} varyanta uygulanacak', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('\u0130ptal')),
        ElevatedButton.icon(onPressed: () { final price = double.tryParse(controller.text); if (price != null && price >= 0) Navigator.pop(context, price); }, icon: const Icon(Icons.check, size: 18), label: const Text('Uygula'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success)),
      ],
    ),
  );
  if (result != null) {
    for (var variant in state.variants) { variant.salePrice = result; }
    onChanged();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u2705 ${state.variants.length} varyanta \u20ba${result.toStringAsFixed(2)} sat\u0131\u015f fiyat\u0131 uyguland\u0131!'), backgroundColor: AppColors.success));
  }
}
