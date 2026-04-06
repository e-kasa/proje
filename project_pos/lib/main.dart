import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ortam bilgisini konsola yazdır (sadece debug modunda)
  if (kDebugMode) {
    debugPrint('╔══════════════════════════════════════════');
    debugPrint('║ Ortam   : ${EnvConfig.environmentName}');
    debugPrint('║ Base URL: ${EnvConfig.baseUrl}');
    debugPrint('║ Logging : ${EnvConfig.enableLogging ? "Aktif" : "Kapalı"}');
    debugPrint('╚══════════════════════════�