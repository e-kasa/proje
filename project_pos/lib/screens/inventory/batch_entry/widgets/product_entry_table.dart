import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/batch_entry_provider.dart';
import '../models/batch_entry_models.dart';

class ProductEntryTable extends ConsumerWidget {
  const ProductEntryTable({super.key});

  static final _currencyFormat =
      NumberFormat.currency(locale: 'tr_TR', symbol: '\u20BA');
  static const _vatOptions = [0.0, 1.0, 8.0, 10.0, 18.0, 20.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchEntryProvider);
    final rows = state.rows;

    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'Henuz urun eklenmedi',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4),
              Text(
                'Barkod tarayin veya manuel ekleyin',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    return isDesktop ? _buildDataTable(rows, ref) : _buildCardList(rows, ref);
  }

  // ---------------------------------------------------------------------------
  // DESKTOP DATA TABLE
  // ---------------------------------------------------------------------------
  Widget _buildDataTable(List<BatchEntryRow> rows, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 42,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('#'), numeric: true),
          DataColumn(label: Text('Durum')),
          DataColumn(label: Text('Barkod')),
          DataColumn(label: Text('Urun Adi')),
          DataColumn(label: Text('OEM No')),
          DataColumn(label: Text('Alis \u20BA'), numeric: true),
          DataColumn(label: Text('Satis \u20BA'), numeric: true),
          DataColumn(label: Text('KDV %'), numeric: true),
          DataColumn(label: Text('Adet'), numeric: true),
          DataColumn(label: Text('Toplam \u20BA'), numeric: true),
          DataColumn(label: Text('Islem')),
        ],
        rows: List.generate(rows.length, (i) {
          final row = rows[i];
          return DataRow(
            key: ValueKey(row.id),
            color: WidgetStateProperty.resolveWith((_) {
              if (row.hasError) return AppColors.bgDanger;
              if (row.isSaved) return AppColors.bgSuccess.withValues(alpha: 0.3);
              return null;
            }),
            cells: [
              DataCell(Text('${i + 1}')),
              DataCell(_statusBadge(row)),
              DataCell(_editableCell(ref, row, 'barcode', row.barcode,
                  readOnly: row.isExisting, width: 130)),
              DataCell(_editableCell(ref, row, 'productName', row.productName,
                  readOnly: row.isExisting, width: 180)),
              DataCell(_editableCell(ref, row, 'oemNumber', row.oemNumber ?? '',
                  width: 120)),
              DataCell(_numberCell(ref, row, 'purchasePrice', row.purchasePrice)),
              DataCell(_numberCell(ref, row, 'salePrice', row.salePrice)),
              DataCell(_vatDropdown(ref, row)),
              DataCell(_quantityCell(ref, row)),
              DataCell(
                Text(
                  _currencyFormat.format(row.lineTotal),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(_actionButtons(ref, row)),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE CARD LIST
  // ---------------------------------------------------------------------------
  Widget _buildCardList(List<BatchEntryRow> rows, WidgetRef ref) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        return Card(
          key: ValueKey(row.id),
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: row.hasError
                  ? AppColors.danger
                  : row.isSaved
                      ? AppColors.success
                      : AppColors.border,
            ),
          ),
          child: ExpansionTile(
            leading: _statusIcon(row),
            title: Text(
              row.productName.isNotEmpty ? row.productName : 'Yeni Urun',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Adet: ${row.quantity} x ${_currencyFormat.format(row.salePrice)}'
              ' = ${_currencyFormat.format(row.lineTotal)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.danger,
              onPressed: () => _confirmRemove(ref, row),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _mobileField(ref, row, 'Barkod', 'barcode', row.barcode,
                        readOnly: row.isExisting),
                    _mobileField(
                        ref, row, 'Urun Adi', 'productName', row.productName,
                        readOnly: row.isExisting),
                    _mobileField(
                        ref, row, 'OEM No', 'oemNumber', row.oemNumber ?? ''),
                    _mobileNumberField(
                        ref, row, 'Alis \u20BA', 'purchasePrice', row.purchasePrice),
                    _mobileNumberField(
                        ref, row, 'Satis \u20BA', 'salePrice', row.salePrice),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                              width: 80,
                              child: Text('KDV %',
                                  style: TextStyle(fontSize: 13))),
                          Expanded(child: _vatDropdown(ref, row)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                              width: 80,
                              child:
                                  Text('Adet', style: TextStyle(fontSize: 13))),
                          Expanded(child: _quantityCell(ref, row)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _statusBadge(BatchEntryRow row) {
    switch (row.status) {
      case RowStatus.newProduct:
        return _chip('Yeni', AppColors.orange);
      case RowStatus.existing:
      case RowStatus.matched:
        return _chip('Mevcut', AppColors.success);
      case RowStatus.error:
        return Tooltip(
          message: row.errorMessage ?? 'Hata',
          child: _chip('Hata', AppColors.danger),
        );
      case RowStatus.saving:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case RowStatus.saved:
        return _chip('\u2713 Kaydedildi', AppColors.info);
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statusIcon(BatchEntryRow row) {
    switch (row.status) {
      case RowStatus.newProduct:
        return const Icon(Icons.fiber_new, color: AppColors.orange, size: 24);
      case RowStatus.existing:
      case RowStatus.matched:
        return const Icon(Icons.check_circle, color: AppColors.success, size: 24);
      case RowStatus.error:
        return const Icon(Icons.error, color: AppColors.danger, size: 24);
      case RowStatus.saving:
        return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2));
      case RowStatus.saved:
        return const Icon(Icons.verified, color: AppColors.info, size: 24);
    }
  }

  Widget _editableCell(
    WidgetRef ref,
    BatchEntryRow row,
    String field,
    String value, {
    bool readOnly = false,
    double width = 120,
  }) {
    if (readOnly || row.isSaved) {
      return SizedBox(width: width, child: Text(value, overflow: TextOverflow.ellipsis));
    }
    return SizedBox(
      width: width,
      child: TextFormField(
        initialValue: value,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => _updateField(ref, row.id, field, v),
      ),
    );
  }

  Widget _numberCell(
      WidgetRef ref, BatchEntryRow row, String field, double value) {
    if (row.isSaved) {
      return Text(_currencyFormat.format(value));
    }
    return SizedBox(
      width: 100,
      child: TextFormField(
        initialValue: value > 0 ? value.toStringAsFixed(2) : '',
        style: const TextStyle(fontSize: 13),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed != null) _updateField(ref, row.id, field, parsed);
        },
      ),
    );
  }

  Widget _vatDropdown(WidgetRef ref, BatchEntryRow row) {
    if (row.isSaved) return Text('%${row.vatRate.toInt()}');
    return DropdownButton<double>(
      value: row.vatRate,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: _vatOptions
          .map((v) =>
              DropdownMenuItem(value: v, child: Text('%${v.toInt()}')))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          ref.read(batchEntryProvider.notifier).updateRow(row.id, vatRate: v);
        }
      },
    );
  }

  Widget _quantityCell(WidgetRef ref, BatchEntryRow row) {
    final notifier = ref.read(batchEntryProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _smallButton(Icons.remove, () {
          if (row.quantity > 1 && !row.isSaved) {
            notifier.updateRow(row.id, quantity: row.quantity - 1);
          }
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('${row.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        _smallButton(Icons.add, () {
          if (!row.isSaved) {
            notifier.updateRow(row.id, quantity: row.quantity + 1);
          }
        }),
      ],
    );
  }

  Widget _smallButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.bgLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _actionButtons(WidgetRef ref, BatchEntryRow row) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (row.isNew && !row.isSaved)
          IconButton(
            icon: const Icon(Icons.edit_note, size: 20),
            tooltip: 'Detaylar',
            color: AppColors.primary,
            onPressed: () {
              // QuickProductDialog will be opened from parent screen
              ref
                  .read(batchEntryProvider.notifier)
                  .updateRow(row.id, isExpanded: !row.isExpanded);
            },
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Sil',
          color: AppColors.danger,
          onPressed: () => _confirmRemove(ref, row),
        ),
      ],
    );
  }

  void _confirmRemove(WidgetRef ref, BatchEntryRow row) {
    ref.read(batchEntryProvider.notifier).removeRow(row.id);
  }

  // ---------------------------------------------------------------------------
  // MOBILE FIELD HELPERS
  // ---------------------------------------------------------------------------

  Widget _mobileField(
    WidgetRef ref,
    BatchEntryRow row,
    String label,
    String field,
    String value, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value,
        readOnly: readOnly || row.isSaved,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) => _updateField(ref, row.id, field, v),
      ),
    );
  }

  Widget _mobileNumberField(
    WidgetRef ref,
    BatchEntryRow row,
    String label,
    String field,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value > 0 ? value.toStringAsFixed(2) : '',
        readOnly: row.isSaved,
        style: const TextStyle(fontSize: 13),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed != null) _updateField(ref, row.id, field, parsed);
        },
      ),
    );
  }

  void _updateField(WidgetRef ref, String rowId, String field, dynamic value) {
    final notifier = ref.read(batchEntryProvider.notifier);
    switch (field) {
      case 'barcode':
        notifier.updateRow(rowId, barcode: value as String);
      case 'productName':
        notifier.updateRow(rowId, productName: value as String);
      case 'oemNumber':
        notifier.updateRow(rowId, oemNumber: value as String);
      case 'purchasePrice':
        notifier.updateRow(rowId, purchasePrice: value as double);
      case 'salePrice':
        notifier.updateRow(rowId, salePrice: value as double);
    }
  }
}
