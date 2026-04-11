import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_logger.dart';
import '../../services/service_locator.dart';

/// İade nedenleri
const List<Map<String, String>> _returnReasons = [
  {'value': 'damaged', 'label': 'Hasarlı Ürün'},
  {'value': 'wrong_product', 'label': 'Yanlış Ürün'},
  {'value': 'customer_return', 'label': 'Müşteri İadesi'},
  {'value': 'defective', 'label': 'Arızalı / Kusurlu'},
  {'value': 'other', 'label': 'Diğer'},
];

class SaleReturnScreen extends ConsumerStatefulWidget {
  final String saleId;
  const SaleReturnScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleReturnScreen> createState() => _SaleReturnScreenState();
}

class _SaleReturnScreenState extends ConsumerState<SaleReturnScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic> _sale = {};
  List<_ReturnItem> _returnItems = [];
  String _selectedReason = 'customer_return';
  final _noteCtrl = TextEditingController();

  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(salesServiceProvider);
      final data = await service.getSaleById(widget.saleId);
      final items = (data['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      setState(() {
        _sale = data;
        _returnItems = items
            .map((item) => _ReturnItem(
                  original: item,
                  maxQuantity: (item['quantity'] as num?)?.toInt() ?? 1,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ─── Computed ──────────────────────────────────────────────────────────────

  List<_ReturnItem> get _selectedItems =>
      _returnItems.where((i) => i.selected).toList();

  double get _totalReturnAmount => _selectedItems.fold(0.0, (sum, item) {
        final unitPrice =
            (item.original['unitPrice'] as num?)?.toDouble() ?? 0;
        final discount =
            (item.original['discount'] as num?)?.toDouble() ?? 0;
        final taxRate =
            (item.original['taxRate'] as num?)?.toDouble() ?? 0;
        final linePrice = unitPrice * item.returnQuantity;
        final afterDiscount = linePrice - (linePrice * discount / 100);
        final withTax = afterDiscount + (afterDiscount * taxRate / 100);
        return sum + withTax;
      });

  bool get _canSubmit =>
      _selectedItems.isNotEmpty && !_isSubmitting;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      appBar: AppAppBar.standard(
        title: 'Satış İadesi',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSaleInfo(theme),
                            const SizedBox(height: 16),
                            _buildReasonSection(theme),
                            const SizedBox(height: 16),
                            _buildItemsSection(theme),
                            const SizedBox(height: 16),
                            _buildNoteSection(theme),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(theme),
                  ],
                ),
    );
  }

  // ─── Sale Info ─────────────────────────────────────────────────────────────

  Widget _buildSaleInfo(ThemeData theme) {
    final saleNo =
        _sale['saleNumber']?.toString() ?? _sale['id']?.toString() ?? '-';
    final customerName = _sale['customerName']?.toString() ??
        _sale['customer']?.toString() ??
        'Perakende Satış';
    final dateStr = _sale['createdAt']?.toString() ??
        _sale['saleDate']?.toString();
    final dateDisplay = dateStr != null
        ? _dateTimeFmt.format(DateTime.tryParse(dateStr) ?? DateTime.now())
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgInfo.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long,
                color: AppColors.info, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$saleNo',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '$customerName  •  $dateDisplay',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reason Section ────────────────────────────────────────────────────────

  Widget _buildReasonSection(ThemeData theme) {
    return Container(
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
              const Icon(Icons.help_outline,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'İade Nedeni',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _returnReasons.map((r) {
              return DropdownMenuItem(
                value: r['value'],
                child: Text(r['label']!),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedReason = val);
            },
          ),
        ],
      ),
    );
  }

  // ─── Items Section ─────────────────────────────────────────────────────────

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
              'İade Edilecek Ürünler',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Tümünü seç
            TextButton.icon(
              onPressed: () {
                final allSelected =
                    _returnItems.every((i) => i.selected);
                setState(() {
                  for (final item in _returnItems) {
                    item.selected = !allSelected;
                    if (!item.selected) item.returnQuantity = 0;
                    if (item.selected && item.returnQuantity == 0) {
                      item.returnQuantity = item.maxQuantity;
                    }
                  }
                });
              },
              icon: Icon(
                _returnItems.every((i) => i.selected)
                    ? Icons.deselect
                    : Icons.select_all,
                size: 16,
              ),
              label: Text(
                _returnItems.every((i) => i.selected)
                    ? 'Seçimi Kaldır'
                    : 'Tümünü Seç',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_returnItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('Satışta ürün bilgisi bulunamadı',
                    style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          )
        else
          ...List.generate(_returnItems.length, (index) {
            return _buildReturnItemCard(_returnItems[index], index, theme);
          }),
      ],
    );
  }

  Widget _buildReturnItemCard(
      _ReturnItem item, int index, ThemeData theme) {
    final name = item.original['productName']?.toString() ??
        item.original['name']?.toString() ??
        'Ürün';
    final unitPrice =
        (item.original['unitPrice'] as num?)?.toDouble() ?? 0;
    final originalQty = item.maxQuantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.selected
            ? AppColors.warning.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.selected
              ? AppColors.warning.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox
              Checkbox(
                value: item.selected,
                activeColor: AppColors.warning,
                onChanged: (val) {
                  setState(() {
                    item.selected = val ?? false;
                    if (item.selected && item.returnQuantity == 0) {
                      item.returnQuantity = item.maxQuantity;
                    }
                    if (!item.selected) item.returnQuantity = 0;
                  });
                },
              ),
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
                      name,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt.format(unitPrice)} x $originalQty adet',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Miktar seçici (sadece seçiliyse)
          if (item.selected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 48), // checkbox offset
                Text(
                  'İade miktarı:',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                // Miktar kontrol
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _qtyButton(Icons.remove, () {
                        if (item.returnQuantity > 1) {
                          setState(() => item.returnQuantity--);
                        }
                      }),
                      Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.returnQuantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _qtyButton(Icons.add, () {
                        if (item.returnQuantity < item.maxQuantity) {
                          setState(() => item.returnQuantity++);
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '/ $originalQty',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  // ─── Note Section ──────────────────────────────────────────────────────────

  Widget _buildNoteSection(ThemeData theme) {
    return Container(
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
              const Icon(Icons.notes_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'İade Notu',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'İade ile ilgili not ekleyin (opsiyonel)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toplam iade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İade Tutarı',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${_selectedItems.length} kalem, '
                      '${_selectedItems.fold<int>(0, (s, i) => s + i.returnQuantity)} adet',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  _fmt.format(_totalReturnAmount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Gönder
            AppButton.primary(
              text: _isSubmitting ? 'Kaydediliyor...' : 'İadeyi Onayla',
              icon: Icons.assignment_return,
              onPressed: _canSubmit ? _submit : null,
              isLoading: _isSubmitting,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Onay dialog'u
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İadeyi Onayla'),
        content: Text(
          '${_selectedItems.length} kalem, toplam ${_fmt.format(_totalReturnAmount)} tutarında '
          'iade işlemi yapılacak.\n\nStok otomatik olarak güncellenecektir.\n\nDevam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final reasonLabel = _returnReasons
          .firstWhere((r) => r['value'] == _selectedReason)['label']!;

      final payload = {
        'reason': _selectedReason,
        'reasonLabel': reasonLabel,
        'notes': _noteCtrl.text.trim(),
        'totalReturnAmount': _totalReturnAmount,
        'stockMovementType': 'SALE_RETURN_IN',
        'items': _selectedItems.map((item) {
          return {
            'productId': item.original['productId']?.toString() ??
                item.original['id']?.toString(),
            'productName': item.original['productName'] ??
                item.original['name'],
            'quantity': item.returnQuantity,
            'unitPrice':
                (item.original['unitPrice'] as num?)?.toDouble() ?? 0,
            'discount':
                (item.original['discount'] as num?)?.toDouble() ?? 0,
            'taxRate':
                (item.original['taxRate'] as num?)?.toDouble() ?? 0,
            'reason': _selectedReason,
          };
        }).toList(),
      };

      await ref
          .read(salesServiceProvider)
          .createSaleReturn(widget.saleId, payload);

      if (mounted) {
        AppToast.success(context, 'Satış iadesi başarıyla oluşturuldu');
        context.pop(true); // true = iade tamamlandı
      }
    } catch (e) {
      AppLogger.error('Satış iadesi hatası', tag: 'SaleReturn', error: e);
      setState(() => _isSubmitting = false);
      if (mounted) {
        AppToast.error(context, 'İade hatası: $e');
      }
    }
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'Hata', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppButton.primary(
            text: 'Tekrar Dene',
            icon: Icons.refresh,
            onPressed: _load,
          ),
        ],
      ),
    );
  }
}

// ─── Return Item Model ───────────────────────────────────────────────────────

class _ReturnItem {
  final Map<String, dynamic> original;
  final int maxQuantity;
  bool selected = false;
  int returnQuantity = 0;

  _ReturnItem({
    required this.original,
    required this.maxQuantity,
  });
}