import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_pos/models/stock_management_models.dart';
import 'package:project_pos/services/service_locator.dart';
import 'package:project_pos/core/widgets/widgets.dart';
import 'package:project_pos/core/theme/app_colors.dart';
import 'package:project_pos/core/utils/i18n_helper.dart';

/// STOK TRANSFER ONAY EKRANI
/// Transfer taleplerini inceleyip onaylama/reddetme
class StockTransferReviewScreen extends ConsumerStatefulWidget {
  final String? transferId;

  const StockTransferReviewScreen({
    Key? key,
    this.transferId,
  }) : super(key: key);

  @override
  ConsumerState<StockTransferReviewScreen> createState() =>
      _StockTransferReviewScreenState();
}

class _StockTransferReviewScreenState
    extends ConsumerState<StockTransferReviewScreen> {
  StockTransferResponse? _response;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(stockServiceProvider);
      final data = await service.getStockMovements();
      // Build response from API data
      final items = (data as List).map((item) {
        return TransferItem.fromJson(item as Map<String, dynamic>);
      }).toList();
      setState(() {
        _response = StockTransferResponse(
          transferId: widget.transferId ?? '-',
          createdBy: '-',
          items: items,
          itemCount: items.length,
          status: TransferStatus.PENDING,
          createdAt: DateTime.now(),
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
    return _response!.items.where((item) => item.hasDecision).length;
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    if (_isLoading) {
      return AppScaffold(
        appBar: AppAppBar.standard(
          title: t('stock.transfer_review'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _response == null) {
      return AppScaffold(
        appBar: AppAppBar.standard(
          title: t('stock.transfer_review'),
        ),
        body: Center(child: Text(t('stock.data_load_failed'))),
      );
    }
    return AppScaffold(
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: t('stock.transfer_review'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_decidedCount}/${_response!.itemCount}',
                style: const TextStyle(
                  color: Colors.black,
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
          // Transfer Bilgileri
          _buildTransferInfo(),

          // Progress Bar
          _buildProgressBar(),

          // Transfer İtem Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _response!.items.length,
              itemBuilder: (context, index) {
                return _buildTransferItemCard(_response!.items[index], index + 1);
              },
            ),
          ),

          // Onay Butonu
          _buildApproveButton(),
        ],
      ),
    );
  }

  Widget _buildTransferInfo() {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t('stock.transfer_id')}: ${_response!.transferId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('stock.created_by')}: ${_response!.createdBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final t = i18nOf(ref);
    final progress = _decidedCount / _response!.itemCount;

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
                t('stock.progress'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_decidedCount / _response!.itemCount * 100).toInt()}%',
                style: TextStyle(
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
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferItemCard(TransferItem item, int index) {
    final t = i18nOf(ref);
    final hasDecision = item.hasDecision;

    Color borderColor = AppColors.border;
    Color headerColor = AppColors.bgLight!;

    if (hasDecision) {
      borderColor = AppColors.success;
      headerColor = AppColors.bgSuccess!;
    } else if (!item.isStockSufficient) {
      borderColor = AppColors.warning;
      headerColor = AppColors.bgWarning!;
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
                    color: item.isStockSufficient
                        ? AppColors.bgSuccess
                        : AppColors.bgWarning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.isStockSufficient
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.productName,
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
                    child: Text(
                      '✓ ${t('stock.decided')}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün Bilgileri
                _buildInfoRow('SKU', item.sku ?? '-'),
                _buildInfoRow(t('stock.barcode'), item.barcode ?? '-'),
                const SizedBox(height: 12),

                // Transfer Detayları
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationCard(
                        t('stock.source'),
                        item.sourceLocation,
                        Icons.output,
                        AppColors.danger,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: _buildLocationCard(
                        t('stock.target'),
                        item.targetLocation!,
                        Icons.input,
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Miktar Bilgisi
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isStockSufficient
                        ? AppColors.bgSuccess
                        : AppColors.bgWarning,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isStockSufficient
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('stock.requested'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${item.requestedQuantity} ${t('stock.unit_piece')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            t('stock.available_stock'),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${item.availableStock} ${t('stock.unit_piece')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.isStockSufficient
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Uyarı Mesajı
                if (!item.isStockSufficient) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWarning,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.needsPartialTransfer
                                ? t('stock.insufficient_stock_partial')
                                : t('stock.source_no_stock'),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Karar Verme Alanı
          if (!hasDecision) _buildDecisionArea(item),

          // Karar Özeti
          if (hasDecision) _buildDecisionSummary(item),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    LocationStock location,
    IconData icon,
    Color color,
  ) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
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
            location.locationName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (location.shelfLocation != null)
            Text(
              '${t('stock.shelf')}: ${location.shelfLocation}',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionArea(TransferItem item) {
    final t = i18nOf(ref);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.isStockSufficient)
            Row(
              children: [
                Expanded(
                  child: _buildDecisionButton(
                    '${t('stock.approve')} (${item.requestedQuantity} ${t('stock.unit_piece')})',
                    Icons.check_circle,
                    AppColors.success,
                    () => _makeDecision(item, TransferAction.APPROVE_FULL),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDecisionButton(
                    t('stock.reject'),
                    Icons.cancel,
                    AppColors.danger,
                    () => _makeDecision(item, TransferAction.REJECT),
                  ),
                ),
              ],
            )
          else if (item.needsPartialTransfer)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        '${t('stock.partial_approve')} (${item.availableStock} ${t('stock.unit_piece')})',
                        Icons.add_task,
                        AppColors.warning,
                        () => _makeDecisionPartial(item),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        t('stock.request_more_info'),
                        Icons.info_outline,
                        AppColors.info,
                        () => _makeDecision(item, TransferAction.REQUEST_MORE_INFO),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDecisionButton(
                        t('stock.reject'),
                        Icons.cancel,
                        AppColors.danger,
                        () => _makeDecision(item, TransferAction.REJECT),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            _buildDecisionButton(
              '${t('stock.reject')} (${t('stock.no_stock')})',
              Icons.cancel,
              AppColors.danger,
              () => _makeDecision(item, TransferAction.REJECT),
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

  Widget _buildDecisionSummary(TransferItem item) {
    final t = i18nOf(ref);
    final decision = item.userDecision!;
    String actionText = '';
    IconData actionIcon = Icons.check;
    Color actionColor = AppColors.success;

    switch (decision.action) {
      case TransferAction.APPROVE_FULL:
        actionText = '${t('stock.fully_approved')} (${item.requestedQuantity} ${t('stock.unit_piece')})';
        actionIcon = Icons.check_circle;
        actionColor = AppColors.success;
        break;
      case TransferAction.APPROVE_PARTIAL:
        actionText = '${t('stock.partially_approved')} (${decision.approvedQuantity} ${t('stock.unit_piece')})';
        actionIcon = Icons.add_task;
        actionColor = AppColors.warning;
        break;
      case TransferAction.REJECT:
        actionText = t('stock.rejected');
        actionIcon = Icons.cancel;
        actionColor = AppColors.danger;
        break;
      case TransferAction.REQUEST_MORE_INFO:
        actionText = t('stock.more_info_requested');
        actionIcon = Icons.info_outline;
        actionColor = AppColors.info;
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
                item.userDecision = null;
              });
            },
            child: Text(t('stock.change')),
          ),
        ],
      ),
    );
  }

  void _makeDecision(TransferItem item, TransferAction action) {
    setState(() {
      item.userDecision = TransferDecision(
        action: action,
        approvedQuantity: action == TransferAction.APPROVE_FULL
            ? item.requestedQuantity
            : null,
      );
    });
  }

  void _makeDecisionPartial(TransferItem item) {
    setState(() {
      item.userDecision = TransferDecision(
        action: TransferAction.APPROVE_PARTIAL,
        approvedQuantity: item.availableStock,
      );
    });
  }

  Widget _buildApproveButton() {
    final t = i18nOf(ref);
    final allDecided = _decidedCount == _response!.itemCount;

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
              '${t('stock.decisions')}: $_decidedCount/${_response!.itemCount}',
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
            text: t('stock.approve'),
          ),
        ],
      ),
    );
  }
}