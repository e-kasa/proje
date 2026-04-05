import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_locator.dart';

class StockMovementHistoryScreen extends ConsumerStatefulWidget {
  const StockMovementHistoryScreen({super.key});

  @override
  ConsumerState<StockMovementHistoryScreen> createState() =>
      _StockMovementHistoryScreenState();
}

class _StockMovementHistoryScreenState
    extends ConsumerState<StockMovementHistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = false;
  String? _error;

  // Filter: 'all', 'in', 'out'
  String _filterType = 'all';

  late DateTimeRange _dateRange;

  static const _inTypes = [
    'PURCHASE_IN',
    'TRANSFER_IN',
    'ADJUSTMENT_IN',
    'SALE_RETURN_IN',
  ];
  static const _outTypes = [
    'SALE_OUT',
    'TRANSFER_OUT',
    'ADJUSTMENT_OUT',
    'PURCHASE_RETURN_OUT',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
    _loadMovements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.getStockMovements(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      );
      if (!mounted) return;
      setState(() {
        _movements = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMovements {
    var list = _movements;

    // Type filter
    if (_filterType == 'in') {
      list = list.where((m) {
        final type = m['movementType']?.toString() ?? '';
        return _inTypes.contains(type);
      }).toList();
    } else if (_filterType == 'out') {
      list = list.where((m) {
        final type = m['movementType']?.toString() ?? '';
        return _outTypes.contains(type);
      }).toList();
    }

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((m) {
        final variantName = m['variantName']?.toString().toLowerCase() ?? '';
        final variantSku = m['variantSku']?.toString().toLowerCase() ?? '';
        final productName = m['productName']?.toString().toLowerCase() ?? '';
        return variantName.contains(query) ||
            variantSku.contains(query) ||
            productName.contains(query);
      }).toList();
    }

    return list;
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {});
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadMovements();
    }
  }

  Color _typeBadgeColor(String type) {
    if (type.contains('TRANSFER')) return AppColors.info;
    if (type.contains('ADJUSTMENT')) return AppColors.purple;
    if (type.endsWith('_IN')) return AppColors.success;
    if (type.endsWith('_OUT')) return AppColors.danger;
    return AppColors.textSecondary;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'PURCHASE_IN':
        return 'Satin Alma';
      case 'TRANSFER_IN':
        return 'Transfer Giris';
      case 'ADJUSTMENT_IN':
        return 'Duzeltme Giris';
      case 'SALE_RETURN_IN':
        return 'Satis Iade';
      case 'SALE_OUT':
        return 'Satis';
      case 'TRANSFER_OUT':
        return 'Transfer Cikis';
      case 'ADJUSTMENT_OUT':
        return 'Duzeltme Cikis';
      case 'PURCHASE_RETURN_OUT':
        return 'Alis Iade';
      default:
        return type;
    }
  }

  bool _isInType(String type) {
    return _inTypes.contains(type);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovements;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Stok Hareket Gecmisi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Tarih Sec',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & date info
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Urun adi veya SKU ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.bgLight,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${_dateRange.start.toString().substring(0, 10)} - ${_dateRange.end.toString().substring(0, 10)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tumu', 'all', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Giris', 'in', AppColors.success),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cikis', 'out', AppColors.danger),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadMovements,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swap_vert,
                                    size: 64, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'Hareket bulunamadi',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMovements,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildMovementCard(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color? color) {
    final isSelected = _filterType == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: chipColor),
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final type = movement['movementType']?.toString() ?? '';
    final quantity = movement['quantity'] as num? ?? 0;
    final variantName = movement['variantName']?.toString() ?? '-';
    final variantSku = movement['variantSku']?.toString() ?? '';
    final createTime = movement['createTime']?.toString() ?? '';
    final dateStr = createTime.length >= 10 ? createTime.substring(0, 10) : createTime;
    final isIn = _isInType(type);
    final badgeColor = _typeBadgeColor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIn ? Icons.arrow_downward : Icons.arrow_upward,
                color: badgeColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variantName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (variantSku.isNotEmpty)
                    Text(
                      variantSku,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel(type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity
            Text(
              '${isIn ? '+' : '-'}$quantity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isIn ? AppColors.success : AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
