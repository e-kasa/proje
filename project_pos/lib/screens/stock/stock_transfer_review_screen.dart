import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stock_management_models.dart';
import '../../services/service_locator.dart';
import '../../core/widgets/widgets.dart';
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
        _error = 'Veri yuklenemedi';
        _isLoading = false;
      });
    }
  }

  int get _decidedCount {
    return _response!.items.where((item) => item.hasDecision).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppAppBar.standard(
          title: 'Transfer Talep Inceleme',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _response == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppAppBar.standard(
          title: 'Transfer Talep Inceleme',
        ),
        body: Center(child: Text(_error ?? 'Veri yuklenemedi')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppAppBar.standard(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Transfer Talep Inceleme',
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer ID: ${_response!.transferId}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oluşturan: ${_response!.createdBy}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                'İlerleme',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_decidedCount / _response!.itemCount * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[700],
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
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferItemCard(TransferItem item, int index) {
    final hasDecision = item.hasDecision;

    Color borderColor = Colors.grey[300]!;
    Color headerColor = Colors.grey[50]!;

    if (hasDecision) {
      borderColor = Colors.green[400]!;
      headerColor = Colors.green[50]!;
    } else if (!item.isStockSufficient) {
      borderColor = Colors.orange[400]!;
      headerColor = Colors.orange[50]!;
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
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.isStockSufficient
                          ? Colors.green[800]
                          : Colors.orange[800],
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
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '✓ Karar Verildi',
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
                _buildInfoRow('Barkod', item.barcode ?? '-'),
                const SizedBox(height: 12),

                // Transfer Detayları
                Row(
                  children: [
                    Expanded(
                      child: _buildLocationCard(
                        'Kaynak',
                        item.sourceLocation,
                        Icons.output,
                        Colors.red,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: _buildLocationCard(
                        'Hedef',
                        item.targetLocation!,
                        Icons.input,
                        Colors.green,
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
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.isStockSufficient
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Talep Edilen',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${item.requestedQuantity} Adet',
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
                            'Mevcut Stok',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${item.availableStock} Adet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.isStockSufficient
                                  ? Colors.green[700]
                                  : Colors.orange[700],
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
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[800], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.needsPartialTransfer
                                ? 'Stok yetersiz! Kısmi onay verebilirsiniz.'
                                : 'Kaynak depoda stok yok!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
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
              color: Colors.grey[600],
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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
              'Raf: ${location.shelfLocation}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDecisionArea(TransferItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.isStockSufficient)
            // Tam onay
            Row(
              children: [
                Expanded(
                  child: _buildDecisionButton(
                    'Onayla (${item.requestedQuantity} Adet)',
                    Icons.check_circle,
                    Colors.green,
                    () => _makeDecision(item, TransferAction.APPROVE_FULL),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDecisionButton(
                    'Reddet',
                    Icons.cancel,
                    Colors.red,
                    () => _makeDecision(item, TransferAction.REJECT),
                  ),
                ),
              ],
            )
          else if (item.needsPartialTransfer)
            // Kısmi onay seçenekleri
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDecisionButton(
                        'Kısmi Onayla (${item.availableStock} Adet)',
                        Icons.add_task,
                        Colors.orange,
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
                        'Ek Bilgi İste',
                        Icons.info_outline,
                        Colors.blue,
                        () => _makeDecision(item, TransferAction.REQUEST_MORE_INFO),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDecisionButton(
                        'Reddet',
                        Icons.cancel,
                        Colors.red,
                        () => _makeDecision(item, TransferAction.REJECT),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Stok yok
            _buildDecisionButton(
              'Reddet (Stok Yok)',
              Icons.cancel,
              Colors.red,
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
    final decision = item.userDecision!;
    String actionText = '';
    IconData actionIcon = Icons.check;
    Color actionColor = Colors.green;

    switch (decision.action) {
      case TransferAction.APPROVE_FULL:
        actionText = 'Tam onaylandı (${item.requestedQuantity} adet)';
        actionIcon = Icons.check_circle;
        actionColor = Colors.green;
        break;
      case TransferAction.APPROVE_PARTIAL:
        actionText = 'Kısmi onaylandı (${decision.approvedQuantity} adet)';
        actionIcon = Icons.add_task;
        actionColor = Colors.orange;
        break;
      case TransferAction.REJECT:
        actionText = 'Reddedildi';
        actionIcon = Icons.cancel;
        actionColor = Colors.red;
        break;
      case TransferAction.REQUEST_MORE_INFO:
        actionText = 'Ek bilgi istendi';
        actionIcon = Icons.info_outline;
        actionColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: actionColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: actionColor.withOpacity(0.3)),
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
            child: const Text('Değiştir'),
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
    final allDecided = _decidedCount == _response!.itemCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Kararlar: $_decidedCount/${_response!.itemCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: allDecided ? () {} : null,
            icon: const Icon(Icons.check),
            label: const Text('Onayla'),
          ),
        ],
      ),
    );
  }
}