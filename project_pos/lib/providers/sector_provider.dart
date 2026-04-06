import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/sector_config.dart';
import 'auth_provider.dart';

/// Giriş yapan kullanıcının şirket sektörüne göre SectorConfig sağlar.
///
/// Kullanım (herhangi bir widget/screen içinde):
///   final cfg = ref.watch(sectorConfigProvider);
///   Text(cfg.labels.productName)   // "Parça" / "Ürün" / "Cihaz" / "Model"
///   if (cfg.fields.showOem) ...
final sectorConfigProvider = Provider<SectorConfig>((ref) {
  final user = ref.watch(authProvider).user;
  final type = SectorTypeExt.fromApi(user?.sectorType);
  return SectorConfig.fromType(type);
});

/// Sadece SectorType enum'u gerekiyorsa
final sectorTypeProvider = Provider<SectorType>((ref) {
  return ref.watch(sectorConfigProvider).type;
});
