import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/batch_entry_models.dart';
import 'package:project_pos/core/widgets/widgets.dart';

class QuickProductDialog extends StatefulWidget {
  final BatchEntryRow row;
  final Function(BatchEntryRow) onSave;

  const QuickProductDialog({
    super.key,
    required this.row,
    required this.onSave,
  });

  /// Shows the dialog and returns the updated row, or null if cancelled.
  static Future<BatchEntryRow?> show(BuildContext context, BatchEntryRow row) {
    return showDialog<BatchEntryRow>(
      context: context,
      builder: (_) => QuickProductDialog(
        row: row,
        onSave: (updated) => Navigator.pop(context, updated),
      ),
    );
  }

  @override
  State<QuickProductDialog> createState() => _QuickProductDialogState();
}

class _QuickProductDialogState extends State<QuickProductDialog> {
  static const _unitOptions = [
    'Adet',
    'Kilogram',
    'Gram',
    'Litre',
    'Metre',
    'Kutu',
    'Paket',
  ];

  late String _selectedUnit;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _minStockCtrl;

  late final List<_PairControllers> _oemControllers;
  late final List<_PairControllers> _crossRefControllers;

  @override
  void initState() {
    super.initState();
    final row = widget.row;

    _selectedUnit = row.unitId != null && _unitOptions.contains(row.unitId)
        ? row.unitId!
        : _unitOptions.first;
    _descriptionCtrl = TextEditingController(text: row.description ?? '');
    _shelfCtrl = TextEditingController(text: row.shelfLocation ?? '');
    _minStockCtrl =
        TextEditingController(text: row.minStockLevel.toString());

    _oemControllers = row.oemList
        .map((m) => _PairControllers(
              first: TextEditingController(text: m['number'] ?? ''),
              second: TextEditingController(text: m['manufacturer'] ?? ''),
            ))
        .toList();

    _crossRefControllers = row.crossRefList
        .map((m) => _PairControllers(
              first: TextEditingController(text: m['code'] ?? ''),
              second: TextEditingController(text: m['brand'] ?? ''),
            ))
        .toList();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _shelfCtrl.dispose();
    _minStockCtrl.dispose();
    for (final c in _oemControllers) {
      c.dispose();
    }
    for (final c in _crossRefControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final t = i18nOf(ref);
        return AlertDialog(
          icon: const Icon(Icons.info_outline, color: AppColors.primary),
          title: Text(
            '${t('batch.product_details')} \u2014 ${widget.row.productName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- Birim dropdown --
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: t('product.unit'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _unitOptions
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedUnit = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // -- Aciklama --
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: t('common.description'),
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -- Raf Konumu --
                  TextFormField(
                    controller: _shelfCtrl,
                    decoration: InputDecoration(
                      labelText: t('product.shelf_location'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // -- Min. Stok Seviyesi --
                  TextFormField(
                    controller: _minStockCtrl,
                    decoration: InputDecoration(
                      labelText: t('product.min_stock_level'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // -- OEM Numaralari --
                  _buildDynamicSection(
                    label: t('product.oem_numbers'),
                    controllers: _oemControllers,
                    firstHint: t('product.oem_no'),
                    secondHint: t('product.manufacturer'),
                    tooltip: t('common.add'),
                    deleteTooltip: t('common.delete'),
                    onAdd: () => setState(() {
                      _oemControllers.add(_PairControllers(
                        first: TextEditingController(),
                        second: TextEditingController(),
                      ));
                    }),
                    onRemove: (i) => setState(() {
                      _oemControllers[i].dispose();
                      _oemControllers.removeAt(i);
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),

                  // -- Capraz Referanslar --
                  _buildDynamicSection(
                    label: t('product.cross_references'),
                    controllers: _crossRefControllers,
                    firstHint: t('product.ref_code'),
                    secondHint: t('product.brand'),
                    tooltip: t('common.add'),
                    deleteTooltip: t('common.delete'),
                    onAdd: () => setState(() {
                      _crossRefControllers.add(_PairControllers(
                        first: TextEditingController(),
                        second: TextEditingController(),
                      ));
                    }),
                    onRemove: (i) => setState(() {
                      _crossRefControllers[i].dispose();
                      _crossRefControllers.removeAt(i);
                    }),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('common.cancel')),
            ),
            AppButton.primary(
              text: t('common.save'),
              onPressed: _onSave,
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic pair-list section
  // ---------------------------------------------------------------------------

  Widget _buildDynamicSection({
    required String label,
    required List<_PairControllers> controllers,
    required String firstHint,
    required String secondHint,
    required String tooltip,
    required String deleteTooltip,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              color: AppColors.primary,
              tooltip: tooltip,
              onPressed: onAdd,
            ),
          ],
        ),
        ...List.generate(controllers.length, (i) {
          final pair = controllers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pair.first,
                    decoration: InputDecoration(
                      hintText: firstHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: pair.second,
                    decoration: InputDecoration(
                      hintText: secondHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.danger,
                  tooltip: deleteTooltip,
                  onPressed: () => onRemove(i),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  void _onSave() {
    final oemList = _oemControllers
        .map((c) => {
              'number': c.first.text.trim(),
              'manufacturer': c.second.text.trim(),
            })
        .where((m) => m['number']!.isNotEmpty)
        .toList();

    final crossRefList = _crossRefControllers
        .map((c) => {
              'code': c.first.text.trim(),
              'brand': c.second.text.trim(),
            })
        .where((m) => m['code']!.isNotEmpty)
        .toList();

    final updated = widget.row.copyWith(
      unitId: _selectedUnit,
      description: _descriptionCtrl.text.trim(),
      shelfLocation: _shelfCtrl.text.trim(),
      minStockLevel: int.tryParse(_minStockCtrl.text) ?? 10,
    )
      ..oemList = oemList
      ..crossRefList = crossRefList;

    widget.onSave(updated);
  }
}

// ---------------------------------------------------------------------------
// Helper: pair of TextEditingControllers for OEM / cross-ref rows
// ---------------------------------------------------------------------------

class _PairControllers {
  final TextEditingController first;
  final TextEditingController second;

  _PairControllers({required this.first, required this.second});

  void dispose() {
    first.dispose();
    second.dispose();
  }
}
