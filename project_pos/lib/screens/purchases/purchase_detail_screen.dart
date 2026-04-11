import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../services/service_locator.dart';
import '../../core/utils/i18n_helper.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseDetailScreen> createState() =>
      _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  String Function(String) get t => i18nOf(ref);

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic> _purchase = {};
  List<Map<String, dynamic>> _items = [];

  // Düzenleme modu
  bool _isEditing = false;
  late TextEditingController _invoiceCtrl;
  late TextEditingController _deliveryNoteCtrl;
  late TextEditingController _notesCtrl;
  DateTime? _selectedDate;

  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _invoiceCtrl = TextEditingController();
    _deliveryNoteCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _deliveryNoteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(purchaseServiceProvider);
      final data = await service.getPurchaseById(widget.purchaseId);

      // Backend items alanını farklı key'lerle döndürebilir
      List<Map<String, dynamic>> items = [];
      final rawItems = data['items'] ?? data['stockMovements'] ?? data['movements'] ?? [];
      if (rawItems is List) {
        items = rawItems
            .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
            .where((e) => e.isNotEmpty)
            .toList();
      }

      setState(() {
        _purchase = data;
        _items = items;
        _isLoading = false;
        _populateEditFields();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _populateEditFields() {
    _invoiceCtrl.text = _purchase['invoiceNumber'] ?? '';
    _deliveryNoteCtrl.text = _purchase['deliveryNoteNumber'] ?? '';
    _notesCtrl.text = _purchase['notes'] ?? '';
    final dateStr = _purchase['purchaseDate']?.toString();
    _selectedDate =
        dateStr != null ? DateTime.tryParse(dateStr) : DateTime.now();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(purchaseServiceProvider);
      final data = {
        'invoiceNumber': _invoiceCtrl.text.trim(),
        'deliveryNoteNumber': _deliveryNoteCtrl.text.trim(),
        'purchaseDate': _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        'notes': _notesCtrl.text.trim(),
      };
      await service.updatePurchase(widget.purchaseId, data);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        AppToast.success(context, t('purchases.updated_success'));
        _load();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppToast.error(context, '${t('common.error')}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = _purchase['isCancelled'] == true;

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: _isEditing ? t('purchases.edit') : t('purchases.detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isEditing) {
              setState(() {
                _isEditing = false;
                _populateEditFields();
              });
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (!_isLoading && _error == null && !cancelled)
            _isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _isEditing = false;
                                  _populateEditFields();
                                });
                              },
                        child: Text(t('common.cancel')),
                      ),
                      TextButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(t('common.save')),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => setState(() => _isEditing = true),
                        tooltip: t('common.edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.assignment_return_outlined,
                            color: Colors.orange),
                        onPressed: () {
                          context
                              .push('/purchases/return/${widget.purchaseId}')
                              .then((result) {
                            if (result == true && mounted) _load();
                          });
                        },
                        tooltip: t('purchases.return'),
                      ),
                    ],
                  ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: t('common.refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(cancelled, theme),
                        const SizedBox(height: 16),
                        _buildHeaderCard(theme),
                        const SizedBox(height: 16),
                        _buildAmountCard(theme),
                        const SizedBox(height: 16),
                        _buildItemsSection(theme),
                        if ((_purchase['notes'] ?? '').toString().isNotEmpty ||
                            _isEditing) ...[
                          const SizedBox(height: 16),
                          _buildNotesCard(theme),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  // ─── Error Display ────────────────────────────────────────────────────────

  Widget _buildError() {
    return AppEmptyState.error(
      title: t('common.load_error'),
      description: _error ?? t('common.unknown_error'),
      actionText: t('common.retry'),
      onAction: _load,
    );
  }

  // ─── Status Banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner(bool cancelled, ThemeData theme) {
    if (cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text(
              t('purchases.purchase_cancelled'),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final remaining =
        ((_purchase['remainingDebt'] as num?)?.toDouble() ?? 0);
    if (remaining > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${t('purchases.remaining_debt')}: ${_fmt.format(remaining)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[800], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text(
            t('purchases.payment_complete'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─── Header Card (Belge Bilgileri) ────────────────────────────────────────

  Widget _buildHeaderCard(ThemeData theme) {
    final dateStr = _purchase['purchaseDate']?.toString();
    final dateDisplay = dateStr != null
        ? _dateFmt.format(DateTime.tryParse(dateStr) ?? DateTime.now())
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: _isEditing ? _buildHeaderEdit(theme) : _buildHeaderView(theme, dateDisplay),
    );
  }

  Widget _buildHeaderView(ThemeData theme, String dateDisplay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _purchase['supplierName'] ?? t('purchases.supplier'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('purchases.supplier'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        _infoRow(Icons.description_outlined, t('purchases.invoice_number'),
            _purchase['invoiceNumber'] ?? '-', theme),
        const SizedBox(height: 10),
        _infoRow(Icons.local_shipping_outlined, t('purchases.delivery_note'),
            _purchase['deliveryNoteNumber'] ?? '-', theme),
        const SizedBox(height: 10),
        _infoRow(Icons.calendar_today_outlined, t('purchases.date'), dateDisplay, theme),
      ],
    );
  }

  Widget _buildHeaderEdit(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              t('purchases.document_info'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _invoiceCtrl,
          decoration: InputDecoration(
            labelText: t('purchases.invoice_number'),
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deliveryNoteCtrl,
          decoration: InputDecoration(
            labelText: t('purchases.delivery_note'),
            prefixIcon:
                const Icon(Icons.local_shipping_outlined, size: 20),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: t('purchases.date'),
              prefixIcon:
                  const Icon(Icons.calendar_today_outlined, size: 20),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: Text(
              _selectedDate != null
                  ? _dateFmt.format(_selectedDate!)
                  : t('purchases.select_date'),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ─── Amount Card ──────────────────────────────────────────────────────────

  Widget _buildAmountCard(ThemeData theme) {
    final total = (_purchase['totalAmount'] as num?)?.toDouble() ?? 0;
    final paid = (_purchase['paidAmount'] as num?)?.toDouble() ?? 0;
    final remaining = (_purchase['remainingDebt'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                t('purchases.amount_info'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _amountTile(
                    t('purchases.total'), total, AppColors.primary, theme),
              ),
              Expanded(
                child:
                    _amountTile(t('purchases.paid'), paid, Colors.green, theme),
              ),
              Expanded(
                child: _amountTile(
                    t('purchases.remaining'), remaining, Colors.orange, theme),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ödeme ilerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? (paid / total).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining > 0 ? Colors.orange : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total > 0
                ? '%${((paid / total) * 100).toStringAsFixed(0)} ${t('purchases.paid_percent')}'
                : '',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _amountTile(
      String label, double amount, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          _fmt.format(amount),
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // ─── Items Section ────────────────────────────────────────────────────────

  Widget _buildItemsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              t('purchases.items_section'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_items.length} ${t('purchases.items')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          AppEmptyState.noData(
            title: t('purchases.no_items_title'),
            description: t('purchases.no_items_description'),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _buildItemCard(item, idx, theme);
          }),
      ],
    );
  }

  Widget _buildItemCard(
      Map<String, dynamic> item, int index, ThemeData theme) {
    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
    final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0;
    final rawLineTotal = (item['lineTotal'] as num?)?.toDouble();
    final lineTotal = rawLineTotal ?? (unitPrice * qty);
    final sku = item['variantSku']?.toString() ?? item['sku']?.toString() ?? '';
    final variantName = item['variantName']?.toString() ?? item['name']?.toString() ?? '';
    final productName = item['productName']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sıra no
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ürün bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.isNotEmpty ? productName : variantName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variantName.isNotEmpty && productName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      variantName,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                if (sku.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'SKU: $sku',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _itemTag('$qty ${t('purchases.unit')}', Icons.inventory_2_outlined,
                        AppColors.primary, theme),
                    const SizedBox(width: 8),
                    _itemTag('${_fmt.format(unitPrice)} /br',
                        Icons.sell_outlined, Colors.teal, theme),
                  ],
                ),
              ],
            ),
          ),
          // Satır toplamı
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt.format(lineTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('purchases.total'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemTag(
      String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── Notes Card ───────────────────────────────────────────────────────────

  Widget _buildNotesCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                t('purchases.notes'),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _isEditing
              ? TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('purchases.add_note'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Text(
                  _notesCtrl.text.isEmpty ? t('common.empty') : _notesCtrl.text,
                  style: theme.textTheme.bodySmall,
                ),
        ],
      ),
    );
  }
}