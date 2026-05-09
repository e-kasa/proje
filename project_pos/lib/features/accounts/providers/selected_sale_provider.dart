import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sprint 11f — AccountsHub sağ panelinde gösterilecek seçili satış.
///
/// `null` → cari ekstresi (mevcut [StatementDetailPanel]) gösterilir.
/// dolu (saleId) → [SaleDetailPanel] gösterilir (ürünler + "Bu satışa öde").
///
/// Set noktaları:
///   - AccountsListPanel plaka modu satış kartına tıklayınca
///   - StatementDetailPanel SALE/COLLECTION tipi `_TxRow`'a tıklayınca
/// Reset: cari değiştiğinde, sale detail "← Ekstreye dön" butonuyla.
final selectedSaleProvider = StateProvider<String?>((ref) => null);
