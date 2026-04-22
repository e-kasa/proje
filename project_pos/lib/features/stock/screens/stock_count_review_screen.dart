import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/models/stock_management_models.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// STOK SAYIM INCELEME EKRANI
/// Sayim sonuclarini inceleyip kabul/red/duzeltme yapma
class StockCountReviewScreen extends ConsumerStatefulWidget {
  final String? countId;

  const StockCountReviewScreen({
    Key? key,
    this.countId,
  }) : super(key: key);

  @override
  ConsumerState<StockCountReviewScreen> createState() => _StockCountReviewScreenState();
}

class _StockCountReviewScreenState extends ConsumerState<StockCountReviewScreen> {
  StockCountResponse? _response;
  bool _isLoading = true;
  String? _error;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.performStockCount([]);
      final products = (data['products'] as List?)?.map((item) {
        return CountedProduct.fromJson(item as Map<String, dynamic>);
      }).toList() ?? [];
      setState(() {
        _response = StockCountResponse(
          countId: widget.countId ?? '-',
          countedBy: '-',
          products: products,
          productCount: products.length,
          countDate: DateTime.now(),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'data_load_failed';
        _isLoading = false;
      });
    }
  }

  int get _decidedCount {
    return _response!.products.where((p) => p.hasDecision).length;
  }

  List<CountedProduct> get _filteredProducts {
    switch (_filterType) {
      case 'has_diff':
        return _response!.products.where((p) => p.hasDifference).toList();
      case 'overage':
        return _response!.products.where((p) => p.isOverage).toList();
      case 'shortage':
        return _response!.products.where((p) => p.isShortage).toList();
      case 'no_diff':
        return _response!.products.where((p) => !p.hasDifference).toList();
      default:
        return _response!.products;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    if (_isLoading) {
      return AppScaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _response == null) {
      return AppScaffold(
        body: Center(child: Text(t('stock.data_load_failed'))),
      );
    }
    return AppScaffold(
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: t('stock.count_review'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_decidedCount}/${_response!.productCount}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sayım Bilgileri
          _buildCountInfo(),

          // Filtre Butonları
          _buildFilterButtons(),

          // Progress Bar
          _buildProgressBar(),

          // Ürün Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredProducts[index], index + 1);
              },
            ),
          ),

          // Kaydet Butonu
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCountInfo() {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.fact_check, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t('stock.count_id')}: ${_response!.countId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t('stock.counted_by')}: ${_response!.countedBy}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final t = i18nOf(ref);
    final filters = {
      'all': t('common.all'),
      'has_diff': t('stock.has_difference'),
      'overage': t('stock.overage'),
      'shortage': t('stock.shortage'),
      'no_diff': t('stock.no_difference'),
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((entry) {
            final isSelected = _filterType == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _filterType = entry.key;
                  });
                },
                selectedColor: AppColors.info,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final t = i18nOf(ref);
    final progress = _decidedCount / _response!.productCount;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('stock.review_progress'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_decidedCount / _response!.productCount * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(CountedProduct product, int index) {
    final t = i18nOf(ref);
    final hasDecision = product.hasDecision;

    Color borderColor = AppColors.border;
    Color headerColor = AppColors.bgLight;
    String statusLabel = t('stock.no_difference');

    if (hasDecision) {
      borderColor = AppColors.success;
      headerColor = AppColors.bgSuccess;
      statusLabel = t('stock.decided');
    } else if (product.hasDifference) {
      if (product.differenceLevel == DifferenceLevel.HIGH) {
        borderColor = AppColors.danger;
        headerColor = AppColors.bgDanger;
        statusLabel = t('stock.high_difference');
      } else if (product.differenceLevel == DifferenceLevel.MEDIUM) {
        borderColor = AppColors.warning;
        headerColor = AppColors.bgWarning;
        statusLabel = t('stock.medium_difference');
      } else {
        borderColor = AppColors.warning;
        headerColor = AppColors.bgWarning;
        statusLabel = t('stock.low_difference');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasDecision)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Ürün Bilgileri
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SKU: ${product.sku ?? '-'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${t('stock.barcode')}: ${product.barcode ?? '-'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${t('stock.location')}: ${product.locationName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sayım Karşılaştırması
                Row(
                  children: [
                    Expanded(
                      child: _buildStockBox(
                        t('stock.system_stock'),
                        product.systemStock,
                        Icons.computer,
                        AppColors.info,
                      ),
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: _buildStockBox(
                        t('stock.counted_stock'),
                        product.countedStock,
                        Icons.fact_check,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fark Gösterimi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: product.hasDifference
                        ? (product.isOverage
                            ? AppColors.bgSuccess
                            : AppColors.bgDanger)
                        : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: product.hasDifference
                          ? (product.isOverage
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.danger.withValues(alpha: 0.3))
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        product.isOverage
                            ? Icons.add_circle_outline
                            : product.isShortage
                                ? Icons.remove_circle_outline
                                : Icons.check_circle_outline,
                        color: product.hasDifference
                            ? (product.isOverage
                                ? AppColors.success
                                : AppColors.danger)
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${t('stock.difference')}: ${product.difference >= 0 ? '+' : ''}${product.difference} ${t('stock.unit_piece')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: product.hasDifference
                              ? (product.isOverage
                                  ? AppColors.success
                                  : AppColors.danger)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Karar Verme Alanı
          if (!hasDecision) _buildDecisionArea(product),

          // Karar Özeti
          if (hasDecision) _buildDecisionSummary(product),
        ],
      ),
    );
  }

  Widget _buildStockBox(String label, int value, IconData icon, Color color) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$value ${t('stock.unit_piece')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionArea(CountedProduct product) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          if (product.hasDifference)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        t('stock.accept_count'),
                        Icons.check_circle,
                        AppColors.success,
                        () => _makeDecision(product, CountAction.ACCEPT_COUNT),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        t('stock.recount'),
                        Icons.replay,
                        AppColors.warning,
                        () => _makeDecision(product, CountAction.RECOUNT),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDecisionButton(
                        t('stock.ignore'),
                        Icons.close,
                        AppColors.textMuted,
                        () => _makeDecision(product, CountAction.IGNORE),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            _buildDecisionButton(
              t('stock.approve'),
              Icons.check,
              AppColors.success,
              () => _makeDecision(product, CountAction.ACCEPT_COUNT),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AppButton.primary(
      text: label,
      icon: icon,
      size: ButtonSize.small,
      onPressed: onTap,
    );
  }

  Widget _buildDecisionSummary(CountedProduct product) {
    final t = i18nOf(ref);
    final decision = product.userDecision!;
    String actionText = '';
    IconData actionIcon = Icons.check;
    Color actionColor = AppColors.success;

    switch (decision.action) {
      case CountAction.ACCEPT_COUNT:
        actionText = t('stock.count_accepted');
        actionIcon = Icons.check_circle;
        actionColor = AppColors.success;
        break;
      case CountAction.RECOUNT:
        actionText = t('stock.recount_scheduled');
        actionIcon = Icons.replay;
        actionColor = AppColors.warning;
        break;
      case CountAction.MANUAL_ADJUST:
        actionText = t('stock.manual_adjust_scheduled');
        actionIcon = Icons.edit;
        actionColor = AppColors.info;
        break;
      case CountAction.IGNORE:
        actionText = t('stock.difference_ignored');
        actionIcon = Icons.close;
        actionColor = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: actionColor.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: actionColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(actionIcon, color: actionColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                product.userDecision = null;
              });
            },
            child: Text(t('stock.change')),
          ),
        ],
      ),
    );
  }

  void _makeDecision(CountedProduct product, CountAction action) {
    setState(() {
      product.userDecision = CountDecision(action: action);
    });
  }

  Widget _buildSaveButton() {
    final t = i18nOf(ref);
    final allDecided = _decidedCount == _response!.productCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${t('stock.decisions')}: $_decidedCount/${_response!.productCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton.primary(
            onPressed: allDecided ? () {} : null,
            icon: Icons.check,
            text: t('common.save'),
          ),
        ],
      ),
    );
  }
}