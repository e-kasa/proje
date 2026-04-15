import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';
import 'package:project_pos/features/inventory/services/document_analyze_service.dart';

/// Fatura/İrsaliye PDF analiz sonuçlarını gösteren bottom sheet.
///
/// Her satır için:
///   ✅ FOUND   → mavi chip — variantId ile mevcut ürün olarak batch'e ekle
///   ⚠️ NOT_FOUND → turuncu chip — yeni ürün olarak batch'e ekle
///
/// Kullanıcı "Toplu Ekle" butonuna basınca [onImport] callback çağrılır.
class DocumentAnalyzeResultSheet extends ConsumerStatefulWidget {
  final DocumentAnalyzeResult result;

  /// Seçilen kalemleri batch entry'e aktar
  /// [selected]: Kullanıcının seçtiği [DocumentAnalyzeItem] listesi
  final void Function(List<DocumentAnalyzeItem> selected) onImport;

  const DocumentAnalyzeResultSheet({
    super.key,
    required this.result,
    required this.onImport,
  });

  static Future<void> show({
    required BuildContext context,
    required DocumentAnalyzeResult result,
    required void Function(List<DocumentAnalyzeItem> selected) onImport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DocumentAnalyzeResultSheet(result: result, onImport: onImport),
    );
  }

  @override
  ConsumerState<DocumentAnalyzeResultSheet> createState() =>
      _DocumentAnalyzeResultSheetState();
}

class _DocumentAnalyzeResultSheetState
    extends ConsumerState<DocumentAnalyzeResultSheet> {
  late final Set<int> _selectedIndices;

  @override
  void initState() {
    super.initState();
    // Varsayılan: tümü seçili
    _selectedIndices =
        Set.from(List.generate(widget.result.items.length, (i) => i));
  }

  List<DocumentAnalyzeItem> get _selectedItems => widget.result.items
      .whereIndexed((i, _) => _selectedIndices.contains(i))
      .toList();

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final result = widget.result;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Tutamaç ───────────────────────────────────────────────────
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // ── Başlık ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.document_scanner_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t("batch.document_analysis")}: ${result.fileName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // ── Özet Çubuğu ───────────────────────────────────────────────
            _SummaryBar(result: result),
            const Divider(height: 1),

            // ── Liste ─────────────────────────────────────────────────────
            Expanded(
              child: result.items.isEmpty
                  ? Center(
                      child: Text(t('batch.document_no_items'),
                          style: const TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: result.items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) => _DocumentItemTile(
                        item: result.items[i],
                        selected: _selectedIndices.contains(i),
                        t: t,
                        onToggle: () => setState(() {
                          if (_selectedIndices.contains(i)) {
                            _selectedIndices.remove(i);
                          } else {
                            _selectedIndices.add(i);
                          }
                        }),
                      ),
                    ),
            ),

            // ── Alt Butonlar ──────────────────────────────────────────────
            _BottomActions(
              selectedCount: _selectedIndices.length,
              hasNewItems: _selectedItems.any((i) => !i.isFound),
              t: t,
              onSelectAll: () => setState(() => _selectedIndices
                  .addAll(List.generate(result.items.length, (i) => i))),
              onClearAll: () =>
                  setState(() => _selectedIndices.clear()),
              onImport: () {
                Navigator.pop(context);
                widget.onImport(_selectedItems);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── ÖZET ÇUBUĞU ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final DocumentAnalyzeResult result;
  const _SummaryBar({required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(
            label: '${result.totalItems} Kalem',
            icon: Icons.list_alt_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            label: '${result.foundItems} Mevcut',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            label: '${result.notFoundItems} Yeni',
            icon: Icons.add_circle_outline,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── KALEM SATIRI ─────────────────────────────────────────────────────────────

class _DocumentItemTile extends StatelessWidget {
  final DocumentAnalyzeItem item;
  final bool selected;
  final VoidCallback onToggle;
  final String Function(String) t;

  const _DocumentItemTile({
    required this.item,
    required this.selected,
    required this.onToggle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isFound = item.isFound;
    final statusColor = isFound ? AppColors.info : AppColors.orange;
    final statusLabel = isFound ? t('batch.match_existing') : t('batch.match_new');
    final statusIcon =
        isFound ? Icons.check_circle_outline : Icons.add_circle_outline;
    final displayName =
        item.matchedProductName ?? item.extractedName ?? item.rawText;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),

            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Durum chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 3),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor)),
                          ],
                        ),
                      ),
                      if (item.matchType != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${_matchTypeLabel(item.matchType!)})',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // NAME match uyarı badge
                  if (item.isNameMatch)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 11, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(t('batch.name_match_warning'),
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.warning)),
                      ]),
                    ),

                  // Ürün adı
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Belgeden çıkarılan kod
                  if (item.extractedCode != null)
                    Text(
                      'Kod: ${item.extractedCode}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),

                  // Fiyat tutarsızlık uyarısı
                  if (item.hasPriceMismatch)
                    Text(t('batch.price_mismatch_warning'),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.danger)),
                ],
              ),
            ),

            // Güven ikonu + miktar ve fiyat
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  item.isHighConfidence  ? Icons.verified_rounded
                  : item.isLowConfidence ? Icons.help_outline_rounded
                  : !item.isFound        ? Icons.add_circle_outline
                  :                        Icons.check_circle_outline,
                  size: 12,
                  color: item.isHighConfidence  ? AppColors.success
                       : item.isLowConfidence   ? AppColors.warning
                       : !item.isFound          ? AppColors.orange
                       :                         AppColors.info,
                ),
                const SizedBox(height: 2),
                if (item.extractedQuantity != null)
                  Text(
                    '${item.extractedQuantity!.toInt()} adet',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                if (item.extractedUnitPrice != null)
                  Text(
                    '₺${item.extractedUnitPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _matchTypeLabel(String type) {
    return switch (type) {
      'BARCODE' => t('batch.match_barcode'),
      'OEM'     => t('batch.match_oem'),
      'NAME'    => t('batch.match_name'),
      _         => type,
    };
  }
}

// ── ALT BUTONLAR ─────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final int selectedCount;
  final bool hasNewItems;
  final String Function(String) t;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final VoidCallback onImport;

  const _BottomActions({
    required this.selectedCount,
    required this.hasNewItems,
    required this.t,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kategori uyarısı (yeni ürün seçilince gösterilir)
          if (hasNewItems)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Text(t('batch.new_items_category_required'),
                  style: const TextStyle(fontSize: 11, color: AppColors.warning),
                  textAlign: TextAlign.center),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: onSelectAll,
                  child: Text(t('common.select_all'),
                      style: const TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: onClearAll,
                  child: Text(t('common.clear'),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: selectedCount == 0 ? null : onImport,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    '$selectedCount ${t("batch.document_items_import")}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── UTIL ─────────────────────────────────────────────────────────────────────

extension _WhereIndexed<T> on Iterable<T> {
  Iterable<T> whereIndexed(bool Function(int index, T element) test) sync* {
    var i = 0;
    for (final e in this) {
      if (test(i, e)) yield e;
      i++;
    }
  }
}
