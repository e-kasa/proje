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
    debugPrint('╚══════════════════════════════════════════');
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Admin Dashboard',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}