import 'package:flutter/material.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/widgets/widgets.dart';

import '../models/wizard_state.dart';

/// Shows a dialog to apply bulk stock quantity to all variants.
Future<void> showBulkStockDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
  required String Function(String) t,
}) async {
  if (state.variants.isEmpty) {
    AppToast.warning(context, t('product.no_variants_yet'));
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(children: [const Icon(Icons.inventory_2, color: AppColors.info, size: 24), const SizedBox(width: 12), Text(t('product.bulk_stock_apply'), style: const TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: t('product.stock_quantity'), hintText: '100', prefixIcon: const Icon(Icons.inventory_2, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} ${t('product.will_be_applied_to_variants')}', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common.cancel'))),
        ElevatedButton.icon(onPressed: () { final qty = int.tryParse(controller.text); if (qty != null && qty >= 0) Navigator.pop(context, qty); }, icon: const Icon(Icons.check, size: 18), label: Text(t('common.apply')), style: ElevatedButton.styleFrom(backgroundColor: AppColors.info)),
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
    if (context.mounted) AppToast.success(context, '${state.variants.length} ${t('product.variants_stock_applied')} ($result)');
  }
}

/// Shows a dialog to apply bulk purchase price to all variants.
Future<void> showBulkPurchasePriceDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
  required String Function(String) t,
}) async {
  if (state.variants.isEmpty) {
    AppToast.warning(context, t('product.no_variants_yet'));
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(children: [const Icon(Icons.attach_money, color: AppColors.danger, size: 24), const SizedBox(width: 12), Text(t('product.bulk_purchase_price'), style: const TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: t('product.purchase_price'), hintText: '100.00', prefixText: '\u20ba ', prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppColors.danger), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} ${t('product.will_be_applied_to_variants')}', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common.cancel'))),
        ElevatedButton.icon(onPressed: () { final price = double.tryParse(controller.text); if (price != null && price >= 0) Navigator.pop(context, price); }, icon: const Icon(Icons.check, size: 18), label: Text(t('common.apply')), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger)),
      ],
    ),
  );
  if (result != null) {
    for (var variant in state.variants) { variant.purchasePrice = result; }
    onChanged();
    if (context.mounted) AppToast.success(context, '${state.variants.length} ${t('product.variants_purchase_applied')} (\u20ba${result.toStringAsFixed(2)})');
  }
}

/// Shows a dialog to apply bulk sale price to all variants.
Future<void> showBulkSalePriceDialog({
  required BuildContext context,
  required WizardState state,
  required VoidCallback onChanged,
  required String Function(String) t,
}) async {
  if (state.variants.isEmpty) {
    AppToast.warning(context, t('product.no_variants_yet'));
    return;
  }
  final controller = TextEditingController();
  final result = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(children: [const Icon(Icons.sell, color: AppColors.success, size: 24), const SizedBox(width: 12), Text(t('product.bulk_sale_price'), style: const TextStyle(fontSize: 16))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(labelText: t('product.sale_price'), hintText: '150.00', prefixText: '\u20ba ', prefixIcon: const Icon(Icons.sell, size: 20, color: AppColors.success), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text('${state.variants.length} ${t('product.will_be_applied_to_variants')}', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t('common.cancel'))),
        ElevatedButton.icon(onPressed: () { final price = double.tryParse(controller.text); if (price != null && price >= 0) Navigator.pop(context, price); }, icon: const Icon(Icons.check, size: 18), label: Text(t('common.apply')), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success)),
      ],
    ),
  );
  if (result != null) {
    for (var variant in state.variants) { variant.salePrice = result; }
    onChanged();
    if (context.mounted) AppToast.success(context, '${state.variants.length} ${t('product.variants_sale_applied')} (\u20ba${result.toStringAsFixed(2)})');

  }
}
