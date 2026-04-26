---
title: Runbook — Yeni Flutter Feature Eklemek
type: synthesis
source: .claude/runbooks/new-feature-flutter.md
ingested: 2026-04-25
last-verified: 2026-04-25
---

# Runbook — Yeni Flutter Feature Eklemek

Önce oku: `project_pos/CLAUDE.md`, `reference/url-routing.md`, `reference/api-response.md`.

---

## 1. Klasör İskeleti

```
lib/features/<name>/
├── di/<name>_di.dart           → Provider tanımları (logic YOK)
├── models/                     → Feature'a özgü data class'lar
├── providers/                  → StateNotifier — autoDispose zorunlu
├── services/                   → ApiClient constructor inject
├── screens/                    → ConsumerStatefulWidget
└── widgets/                    → 2+ screen'in kullandığı widget'lar
```

---

## 2. Service

```dart
// lib/features/<name>/services/my_service.dart
class MyService {
  final ApiClient _apiClient;
  MyService(this._apiClient);   // new'leme YASAK

  Future<List<Map<String,dynamic>>> getItems() async {
    try {
      final res = await _apiClient.get('product/api/v1/my-resource');
      return List<Map<String,dynamic>>.from(res.data['data'] ?? []);
    } catch (e) {
      debugPrint('MyService.getItems hata: $e');
      rethrow;
    }
  }
}
```

---

## 3. DI

```dart
// lib/features/<name>/di/<name>_di.dart
final myServiceProvider = Provider<MyService>(
  (ref) => MyService(ref.watch(apiClientProvider)),
);

final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>(
  (ref) => MyNotifier(ref),
);
```

```dart
// lib/core/di/service_locator.dart — export ekle
export 'package:project_pos/features/<name>/di/<name>_di.dart';
```

---

## 4. Provider / State

```dart
class MyState {
  final List<Map<String,dynamic>> items;
  final bool isLoading;
  final String? error;
  const MyState({this.items = const [], this.isLoading = false, this.error});

  MyState copyWith({...}) => ...;
}

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(const MyState());
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _ref.read(myServiceProvider).getItems();
      state = state.copyWith(items: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

---

## 5. Screen

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = i18nOf(ref);
    final state = ref.watch(myProvider);

    return AppScaffold(
      appBar: AppAppBar.standard(title: t('menu.my_screen')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? AppEmptyState.error(title: t('common.error'), description: state.error!)
              : _buildContent(state, t),
    );
  }

  Widget _buildContent(MyState state, String Function(String) t) {
    // t parametre olarak geç — private method'da i18nOf çağrısı olmaz
    return ...;
  }
}
```

**Kurallar:**
- `Scaffold` yerine `AppScaffold`
- `Colors.blue` yerine `AppColors.info`
- `.withOpacity(0.1)` yerine `.withValues(alpha: 0.1)`
- Hardcode metin yerine `t('key')`
- `const Column(children: [Text(t(...))])` — const içinde t() çağrısı derleme hatası verir, const'u kaldır

---

## 6. Router

```dart
// lib/core/router/app_router.dart
GoRoute(
  path: '/my-screen',
  builder: (ctx, state) => const MyScreen(),
),
```

---

## 7. i18n

`security/src/main/resources/data.sql`'e tüm `t('...')` anahtarlarını ekle:

```sql
('bnd-XX000-0000-0000-NNNNNNNNNNNN', CURRENT_TIMESTAMP, 'SYSTEM', CURRENT_TIMESTAMP, NULL,
 'my_screen.title', 'Ekran Başlığı', 'Screen Title'),
```

Modül prefix → `reference/url-routing.md`'de listelendi.

---

## 8. Checklist

- [ ] Feature-A → Feature-B direkt import YOK (sadece `shared/` veya DI)
- [ ] Service constructor inject, `new X()` yok
- [ ] Provider `autoDispose`
- [ ] `t('key')` — hardcode metin yok
- [ ] URL prefix: `product/` veya `security/`
- [ ] `res.data['data']` okumak
- [ ] i18n anahtarları data.sql'e eklendi
- [ ] Router'a route eklendi
