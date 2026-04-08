import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/widgets.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

// ─── Transfer item model ────────────────────────────────────────────────────

class _TransferItem {
  final String productId;
  final String productName;
  final String sku;
  final int sourceStock;
  int quantity;

  _TransferItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.sourceStock,
    this.quantity = 1,
  });
}

// ─── Location type ──────────────────────────────────────────────────────────

enum _LocationType { warehouse, store }

// ─── Screen ─────────────────────────────────────────────────────────────────

class StockTransferScreen extends ConsumerStatefulWidget {
  const StockTransferScreen({super.key});

  @override
  ConsumerState<StockTransferScreen> createState() =>
      _StockTransferScreenState();
}

class _StockTransferScreenState extends ConsumerState<StockTransferScreen> {
  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Dropdown data
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _stores = [];

  // Source selection
  _LocationType _sourceType = _LocationType.warehouse;
  String? _sourceId;

  // Destination selection
  _LocationType _destType = _LocationType.warehouse;
  String? _destId;

  // Products
  final List<_TransferItem> _items = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;

  bool _isLoading = false;
  bool _isSubmitting = false;

  final _fmt = NumberFormat('#,##0', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ref.read(warehouseServiceProvider).getWarehouses(),
        ref.read(storeServiceProvider).getStores(),
      ]);
      setState(() {
        _warehouses = results[0];
        _stores = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenemedi: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _sourceLocations =>
      _sourceType == _LocationType.warehouse ? _warehouses : _stores;

  List<Map<String, dynamic>> get _destLocations {
    final list =
        _destType == _LocationType.warehouse ? _warehouses : _stores;
    // If same type, exclude the source selection
    if (_sourceType == _destType && _sourceId != null) {
      return list
          .where((l) => _locationCode(l) != _sourceId)
          .toList();
    }
    return list;
  }

  String _locationCode(Map<String, dynamic> loc) {
    return loc['code']?.toString() ?? loc['id']?.toString() ?? '';
  }

  String _locationName(Map<String, dynamic> loc) {
    return loc['name']?.toString() ?? _locationCode(loc);
  }

  int get _totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppAppBar.standard(
        title: 'Stok Transfer Oluştur',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Source location ──
                _buildSectionTitle(
                    'Kaynak Konum', Icons.output_rounded, theme),
                const SizedBox(height: 12),
                _buildLocationSelector(
                  theme: theme,
                  locationType: _sourceType,
                  selectedId: _sourceId,
                  locations: _sourceLocations,
                  onTypeChanged: (type) {
                    setState(() {
                      _sourceType = type;
                      _sourceId = null;
                      // Reset destination if it conflicts
                      _validateDestination();
                    });
                  },
                  onLocationChanged: (id) {
                    setState(() {
                      _sourceId = id;
                      _validateDestination();
                    });
                  },
                  label: 'Kaynak',
                ),

                const SizedBox(height: 20),

                // ── Destination location ──
                _buildSectionTitle(
                    'Hedef Konum', Icons.input_rounded, theme),
                const SizedBox(height: 12),
                _buildLocationSelector(
                  theme: theme,
                  locationType: _destType,
                  selectedId: _destId,
                  locations: _destLocations,
                  onTypeChanged: (type) {
                    setState(() {
                      _destType = type;
                      _destId = null;
                    });
                  },
                  onLocationChanged: (id) =>
                      setState(() => _destId = id),
                  label: 'Hedef',
                ),

                const SizedBox(height: 20),

                // ── Product search ──
                _buildSectionTitle(
                    'Ürünler', Icons.inventory_2_rounded, theme),
                const SizedBox(height: 12),
                _buildProductSearch(theme),

                const SizedBox(height: 12),

                // ── Added items ──
                ..._items
                    .asMap()
                    .entries
                    .map((e) => _buildItemCard(e.key, e.value, theme)),

                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSummary(theme),
                ],

                const SizedBox(height: 16),

                // ── Notes ──
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _inputDeco(
                      'Transfer Notu (opsiyonel)', Icons.notes_rounded, theme),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // ── Submit button ──
                _buildSubmitButton(theme),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ─── Section title ──────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(color: AppColors.primary.withOpacity(0.2))),
      ],
    );
  }

  // ─── Location selector (type chips + dropdown) ──────────────────────────

  Widget _buildLocationSelector({
    required ThemeData theme,
    required _LocationType locationType,
    required String? selectedId,
    required List<Map<String, dynamic>> locations,
    required ValueChanged<_LocationType> onTypeChanged,
    required ValueChanged<String?> onLocationChanged,
    required String label,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type chips
            Row(
              children: [
                FilterChip(
                  label: const Text('Depo'),
                  selected: locationType == _LocationType.warehouse,
                  onSelected: (_) =>
                      onTypeChanged(_LocationType.warehouse),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: locationType == _LocationType.warehouse
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: locationType == _LocationType.warehouse
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Magaza'),
                  selected: locationType == _LocationType.store,
                  onSelected: (_) =>
                      onTypeChanged(_LocationType.store),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: locationType == _LocationType.store
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: locationType == _LocationType.store
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dropdown
            DropdownButtonFormField<String>(
              value: selectedId,
              decoration: _inputDeco(
                '$label Seciniz *',
                locationType == _LocationType.warehouse
                    ? Icons.warehouse_outlined
                    : Icons.store_outlined,
                theme,
              ),
              hint: Text('$label seciniz'),
              isExpanded: true,
              items: locations.map((loc) {
                final code = _locationCode(loc);
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(
                    _locationName(loc),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onLocationChanged,
              validator: (v) => v == null ? '$label seciniz' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Product search ─────────────────────────────────────────────────────

  Widget _buildProductSearch(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Urun adi, SKU veya barkod ile ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchLoading
                  ? const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                    )
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
            onChanged: (v) {
              if (v.trim().length >= 2) {
                _searchProduct(v.trim());
              } else if (v.trim().isEmpty) {
                setState(() => _searchResults = []);
              }
            },
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _searchProduct(v.trim());
            },
          ),
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSearchResultsList(theme),
        ],
      ],
    );
  }

  Widget _buildSearchResultsList(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        border: Border.all(
            color:
                theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color:
              theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        itemBuilder: (_, i) {
          final p = _searchResults[i];
          final name = p['name']?.toString() ?? '';
          final sku = p['sku']?.toString() ?? p['barcode']?.toString() ?? '-';
          final stock = p['stock'] as int? ?? 0;

          final alreadyAdded =
              _items.any((item) => item.productId == (p['id']?.toString() ?? ''));

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: alreadyAdded
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.1),
              child: Icon(
                alreadyAdded
                    ? Icons.check_rounded
                    : Icons.inventory_2_outlined,
                size: 16,
                color: alreadyAdded
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'SKU: $sku  |  Stok: $stock',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: alreadyAdded
                ? const Text('Eklendi',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.success))
                : const Icon(Icons.add_circle_outline,
                    color: AppColors.primary, size: 22),
            onTap: alreadyAdded
                ? null
                : () => _addItem(
                      productId: p['id']?.toString() ?? '',
                      name: name,
                      sku: sku,
                      stock: stock,
                    ),
          );
        },
      ),
    );
  }

  // ─── Item card ──────────────────────────────────────────────────────────

  Widget _buildItemCard(
      int index, _TransferItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color:
                theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.sku}  |  Kaynak Stok: ${item.sourceStock}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _quantityButton(
                    icon: Icons.remove_rounded,
                    onPressed: item.quantity > 1
                        ? () => setState(() => item.quantity--)
                        : null,
                  ),
                  Container(
                    constraints:
                        const BoxConstraints(minWidth: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4),
                    child: Text(
                      '${item.quantity}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _quantityButton(
                    icon: Icons.add_rounded,
                    onPressed: item.quantity < item.sourceStock
                        ? () => setState(() => item.quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Remove
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  color: AppColors.danger, size: 20),
              onPressed: () => setState(() => _items.removeAt(index)),
              tooltip: 'Kaldir',
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityButton(
      {required IconData icon, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null
              ? AppColors.primary
              : AppColors.textMuted,
        ),
      ),
    );
  }

  // ─── Summary ────────────────────────────────────────────────────────────

  Widget _buildSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                '${_items.length} urun',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Toplam Miktar',
                  style: theme.textTheme.bodySmall),
              Text(
                _fmt.format(_totalQuantity),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Submit button ──────────────────────────────────────────────────────

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      height: 52,
      child: AppButton.primary(
        text: _isSubmitting ? 'Kaydediliyor...' : 'Onayla',
        icon: Icons.check,
        onPressed: _isSubmitting ? null : _submit,
      ),
    );
  }

  // ─── Input decoration helper ────────────────────────────────────────────

  InputDecoration _inputDeco(
      String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest
          .withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  void _validateDestination() {
    if (_sourceType == _destType &&
        _sourceId != null &&
        _destId == _sourceId) {
      _destId = null;
    }
  }

  Future<void> _searchProduct(String query) async {
    setState(() => _searchLoading = true);
    try {
      final products = await ref
          .read(productServiceProvider)
          .getProducts(search: query);
      if (mounted) {
        setState(() {
          _searchResults = products;
          _searchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _addItem({
    required String productId,
    required String name,
    required String sku,
    required int stock,
  }) {
    setState(() {
      _items.add(_TransferItem(
        productId: productId,
        productName: name,
        sku: sku,
        sourceStock: stock,
        quantity: 1,
      ));
    });
    _searchCtrl.clear();
    setState(() => _searchResults = []);
  }

  Future<void> _submit() async {
    // Validation
    if (_sourceId == null) {
      _showError('Kaynak konum seciniz');
      return;
    }
    if (_destId == null) {
      _showError('Hedef konum seciniz');
      return;
    }
    if (_items.isEmpty) {
      _showError('En az 1 urun eklemelisiniz');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'sourceType': _sourceType == _LocationType.warehouse
            ? 'warehouse'
            : 'store',
        'sourceId': _sourceId,
        'destinationType': _destType == _LocationType.warehouse
            ? 'warehouse'
            : 'store',
        'destinationId': _destId,
        'notes': _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        'items': _items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
      };

      await ref.read(stockServiceProvider).createTransfer(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer basariyla olusturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/stock/transfer-review');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
      ),
    );
  }
}
