import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/service_locator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_constants.dart';
import '../../core/widgets/app_app_bar.dart';

// ─── Satır modeli ────────────────────────────────────────────────────────────

class _PurchaseItem {
  String variantId;
  String variantSku;
  String variantName;
  int quantity;
  double unitPrice;

  _PurchaseItem({
    required this.variantId,
    required this.variantSku,
    required this.variantName,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get lineTotal => quantity * unitPrice;
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class AddPurchaseScreen extends ConsumerStatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  ConsumerState<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends ConsumerState<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  // Dropdown verileri
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _stores = [];

  // Seçimler
  String? _selectedSupplierId;
  String? _selectedWarehouseId;
  String? _selectedStoreId;
  DateTime _purchaseDate = DateTime.now();

  // Kalemler
  final List<_PurchaseItem> _items = [];
  // Ürün arama sonuçları
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  bool _itemsError = false; // en az 1 ürün şartı

  bool _isLoading = false;
  bool _isSubmitting = false;

  final _fmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ref.read(supplierServiceProvider).getSuppliers(),
        ref.read(warehouseServiceProvider).getWarehouses(),
        ref.read(storeServiceProvider).getStores(),
        ref.read(productServiceProvider).getProducts(),
      ]);

      setState(() {
        _suppliers = results[0];
        _warehouses = results[1];
        _stores = results[2];
        _searchResults = results[3]; // ilk yüklemede tüm ürünler
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  double get _grandTotal => _items.fold(0, (sum, i) => sum + i.lineTotal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppAppBar.standard(
        title: 'Yeni Satın Alma',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_grandTotal > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fmt.format(_grandTotal),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: AppConstants.pagePadding,
                children: [
                  _buildSectionTitle('Tedarikçi Bilgileri', Icons.business_rounded, theme),
                  const SizedBox(height: 12),
                  _buildSupplierDropdown(theme),
                  const SizedBox(height: 12),
                  _buildInvoiceRow(theme),
                  const SizedBox(height: 12),
                  _buildDateRow(theme),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Konum', Icons.warehouse_rounded, theme),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildWarehouseDropdown(theme)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStoreDropdown(theme)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Ürünler', Icons.inventory_2_rounded, theme),
                  const SizedBox(height: 12),
                  _buildItemSearch(theme),
                  const SizedBox(height: 12),
                  ..._items.asMap().entries.map((e) => _buildItemRow(e.key, e.value, theme)),
                  const SizedBox(height: 16),
                  if (_items.isNotEmpty) _buildTotal(theme),
                  const SizedBox(height: 12),
                  _buildNotesField(theme),
                  const SizedBox(height: 24),
                  _buildSubmitButton(theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

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
        Expanded(child: Divider(color: AppColors.primary.withOpacity(0.2))),
      ],
    );
  }

  Widget _buildSupplierDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedSupplierId,
      decoration: _inputDeco('Tedarikçi *', Icons.business_outlined, theme),
      hint: const Text('Tedarikçi seçin'),
      items: _suppliers.map((s) {
        return DropdownMenuItem<String>(
          value: s['id']?.toString(),
          child: Text(s['name']?.toString() ?? s['companyName']?.toString() ?? '-'),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedSupplierId = v),
      validator: (v) => v == null ? 'Tedarikçi seçiniz' : null,
    );
  }

  Widget _buildInvoiceRow(ThemeData theme) {
    return AppInput(
      label: 'Fatura Numarası *',
      controller: _invoiceCtrl,
      prefixIcon: Icons.receipt_outlined,
      validator: (v) => (v == null || v.isEmpty) ? 'Fatura numarası giriniz' : null,
    );
  }

  Widget _buildDateRow(ThemeData theme) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: AppConstants.borderRadiusSmall,
      child: InputDecorator(
        decoration: _inputDeco('Tarih *', Icons.calendar_today_outlined, theme),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_dateFmt.format(_purchaseDate)),
            Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedWarehouseId,
      decoration: _inputDeco('Depo *', Icons.warehouse_outlined, theme),
      hint: const Text('Depo'),
      isExpanded: true,
      items: _warehouses.map((w) {
        // backend PurchaseRequest.warehouseId = plain code ("WH-01"), not UUID
        final code = w['code']?.toString() ?? w['warehouseCode']?.toString() ?? w['id']?.toString();
        return DropdownMenuItem<String>(
          value: code,
          child: Text(w['name']?.toString() ?? code ?? '-', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedWarehouseId = v),
      validator: (v) => v == null ? 'Depo seçiniz' : null,
    );
  }

  Widget _buildStoreDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedStoreId,
      decoration: _inputDeco('Mağaza *', Icons.store_outlined, theme),
      hint: const Text('Mağaza'),
      isExpanded: true,
      items: _stores.map((s) {
        // backend PurchaseRequest.storeId = plain code ("STORE-01"), not UUID
        final code = s['code']?.toString() ?? s['storeCode']?.toString() ?? s['id']?.toString();
        return DropdownMenuItem<String>(
          value: code,
          child: Text(s['name']?.toString() ?? code ?? '-', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedStoreId = v),
      validator: (v) => v == null ? 'Mağaza seçiniz' : null,
    );
  }

  Widget _buildItemSearch(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _itemsError ? AppColors.danger : theme.colorScheme.outlineVariant,
            ),
            borderRadius: AppConstants.borderRadiusSmall,
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Ürün adı veya SKU ile ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_searchCtrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadAllProducts();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    onPressed: _scanBarcode,
                    tooltip: 'Barkod Tara',
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (v) {
              setState(() => _itemsError = false);
              if (v.trim().isEmpty) {
                _loadAllProducts();
              } else {
                _searchProduct(v.trim());
              }
            },
            onSubmitted: (v) => _searchProduct(v.trim()),
          ),
        ),
        if (_itemsError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              'En az 1 ürün eklemelisiniz',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 8),
        // Ürün listesi
        if (_searchResults.isNotEmpty)
          _buildProductList(theme),
      ],
    );
  }

  Widget _buildProductList(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        itemBuilder: (_, i) {
          final p = _searchResults[i];
          final variants = (p['variants'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (variants.isEmpty) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.inventory_2_outlined, size: 16),
              ),
              title: Text(p['name']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
              subtitle: const Text('Varyant yok', style: TextStyle(fontSize: 11)),
              enabled: false,
            );
          }
          if (variants.length == 1) {
            final v = variants.first;
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
              ),
              title: Text(p['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text('SKU: ${v['sku'] ?? '-'}', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
              onTap: () => _addItem(
                v['id']?.toString() ?? '',
                v['sku']?.toString() ?? '',
                v['name']?.toString() ?? p['name']?.toString() ?? '',
              ),
            );
          }
          // Çoklu varyant — genişletilebilir
          return ExpansionTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
            ),
            title: Text(p['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text('${variants.length} varyant', style: const TextStyle(fontSize: 11)),
            children: variants.map((v) {
              final attrs = v['attributes'] != null ? ' — ${v['attributes']}' : '';
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 52, right: 16),
                title: Text('${v['name'] ?? v['sku'] ?? '-'}$attrs', style: const TextStyle(fontSize: 12)),
                subtitle: Text('SKU: ${v['sku'] ?? '-'}', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                onTap: () => _addItem(
                  v['id']?.toString() ?? '',
                  v['sku']?.toString() ?? '',
                  v['name']?.toString() ?? p['name']?.toString() ?? '',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildItemRow(int index, _PurchaseItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Padding(
          padding: AppConstants.paddingSmall,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.variantName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'SKU: ${item.variantSku}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () => setState(() => _items.removeAt(index)),
                    tooltip: 'Kalemi Kaldır',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Miktar
                  _buildNumberField(
                    label: 'Miktar',
                    value: item.quantity.toString(),
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) setState(() => item.quantity = n);
                    },
                  ),
                  const SizedBox(width: 12),
                  // Birim Fiyat
                  _buildNumberField(
                    label: 'Birim Fiyat (₺)',
                    value: item.unitPrice == 0 ? '' : item.unitPrice.toStringAsFixed(2),
                    onChanged: (v) {
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n != null) setState(() => item.unitPrice = n);
                    },
                    isDecimal: true,
                  ),
                  const Spacer(),
                  // Satır toplamı
                  Text(
                    _fmt.format(item.lineTotal),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool isDecimal = false,
  }) {
    return SizedBox(
      width: 110,
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(borderRadius: AppConstants.borderRadiusSmall),
        ),
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (isDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTotal(ThemeData theme) {
    return Container(
      padding: AppConstants.pagePadding,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppConstants.borderRadiusSmall,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.calculate_outlined, size: 18),
            const SizedBox(width: 8),
            Text('${_items.length} kalem', style: theme.textTheme.bodyMedium),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Toplam Tutar', style: theme.textTheme.bodySmall),
              Text(
                _fmt.format(_grandTotal),
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

  Widget _buildNotesField(ThemeData theme) {
    return AppInput(
      label: 'Notlar (opsiyonel)',
      controller: _notesCtrl,
      prefixIcon: Icons.notes_rounded,
      maxLines: 2,
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      height: 52,
      child: AppButton.primary(
        onPressed: _isSubmitting ? null : _submit,
        text: _isSubmitting ? 'Kaydediliyor...' : 'Satın Almayı Kaydet',
        icon: Icons.save_rounded,
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusSmall,
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusSmall,
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
    );
  }

  // ─── Yardımcı eylemler ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr'),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _loadAllProducts() async {
    setState(() => _searchLoading = true);
    try {
      final products = await ref.read(productServiceProvider).getProducts();
      if (mounted) setState(() { _searchResults = products; _searchLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  Future<void> _searchProduct(String query) async {
    if (query.isEmpty) { _loadAllProducts(); return; }
    setState(() => _searchLoading = true);
    try {
      final products = await ref.read(productServiceProvider).getProducts(search: query);
      if (mounted) setState(() { _searchResults = products; _searchLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _addItem(String variantId, String sku, String name) {
    // Aynı varyant zaten ekliyse miktar artır
    final existing = _items.indexWhere((i) => i.variantId == variantId);
    if (existing >= 0) {
      setState(() { _items[existing].quantity++; _itemsError = false; });
    } else {
      setState(() {
        _items.add(_PurchaseItem(variantId: variantId, variantSku: sku, variantName: name));
        _itemsError = false;
      });
    }
    // Arama alanını temizle, tüm ürünleri geri yükle
    _searchCtrl.clear();
    _loadAllProducts();
  }

  void _scanBarcode() {
    context.push('/scanner').then((result) {
      if (result is String && result.isNotEmpty) {
        _searchCtrl.text = result;
        _searchProduct(result);
      }
    });
  }

  Map<String, dynamic> _buildRequest() {
    return {
      'supplierId': _selectedSupplierId,
      'invoiceNumber': _invoiceCtrl.text.trim(),
      'purchaseDate': DateFormat('yyyy-MM-dd').format(_purchaseDate),
      'storeId': _selectedStoreId,
      'warehouseId': _selectedWarehouseId,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'items': _items
          .map((i) => {
                'variantId': i.variantId,
                'quantity': i.quantity,
                'unitPrice': i.unitPrice,
              })
          .toList(),
    };
  }

  bool _isCreditLimitError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('creditlimit') && msg.contains('null');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      setState(() => _itemsError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az 1 ürün kalemi eklenmelidir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Fiyat kontrolü
    final zeroPrice = _items.any((i) => i.unitPrice <= 0);
    if (zeroPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tüm kalemlerin birim fiyatı girilmelidir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(purchaseServiceProvider).createPurchase(_buildRequest());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (!mounted) return;

      if (_isCreditLimitError(e) && _selectedSupplierId != null) {
        _showCreditLimitPrompt();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCreditLimitPrompt() async {
    final supplierName = _suppliers
        .firstWhere((s) => s['id']?.toString() == _selectedSupplierId,
            orElse: () => {})['name']
        ?.toString() ?? 'Tedarikçi';

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('Kredi Limiti Tanımsız'),
        content: Text(
          '"$supplierName" tedarikçisinin kredi limiti tanımlanmamış.\n\n'
          'Satın alma işlemini tamamlamak için önce kredi limitini güncellemek ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Kredi Limiti Güncelle'),
          ),
        ],
      ),
    );

    if (shouldUpdate != true || !mounted) return;

    _showCreditLimitEditor(supplierName);
  }

  Future<void> _showCreditLimitEditor(String supplierName) async {
    final limitCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Kredi Limiti — $supplierName',
                    style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu tedarikçi için kredi limitini belirleyin. '
                  'İşlem sonrasında satın alma otomatik olarak tekrar denenecektir.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Kredi Limiti (₺)',
                  controller: limitCtrl,
                  prefixIcon: Icons.monetization_on_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Limit giriniz';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Geçerli bir tutar giriniz';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        final limit = double.parse(
                            limitCtrl.text.replaceAll(',', '.'));
                        await ref.read(supplierServiceProvider).updateCreditLimit(
                            _selectedSupplierId!, limit);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text('Güncelleme hatası: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(saving ? 'Kaydediliyor...' : 'Kaydet ve Devam Et'),
            ),
          ],
        ),
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kredi limiti güncellendi, satın alma tekrar deneniyor...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      // Kısa bir gecikme ile kullanıcıya bilgi göster, sonra otomatik tekrar dene
      await Future.delayed(const Duration(milliseconds: 500));
      _submit();
    }
  }
}