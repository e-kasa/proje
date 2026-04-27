import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_empty_state.dart';
import 'app_scaffold.dart';

/// Sprint 15 — BaseScaffold
///
/// `AppScaffold` üstüne **AsyncValue switcher** ekleyen ince katman.
/// Ekranlardaki tekrarlayan `if (loading) ... else if (error) ... else body`
/// pattern'ı buraya merkezlenir.
///
/// İki kullanım modu:
///
/// **1. Sync body (eski AppScaffold ile aynı):**
/// ```dart
/// BaseScaffold(
///   appBar: AppAppBar.standard(title: 'X'),
///   body: const MyView(),
/// )
/// ```
///
/// **2. Async body (Riverpod AsyncValue):**
/// ```dart
/// BaseScaffold<List<Foo>>(
///   appBar: AppAppBar.standard(title: 'X'),
///   asyncValue: ref.watch(fooListProvider),
///   onRetry: () => ref.invalidate(fooListProvider),
///   dataBuilder: (data) => ListView(...),
/// )
/// ```
class BaseScaffold<T> extends ConsumerWidget {
  /// Ekranın AppBar'ı. `null` ise gizli (full-screen).
  final PreferredSizeWidget? appBar;

  /// Sync body — `asyncValue` null olduğunda kullanılır.
  final Widget? body;

  /// Async durum — null değilse `dataBuilder` zorunlu.
  final AsyncValue<T>? asyncValue;

  /// `asyncValue.when(data:)` callback'i — `body` ile birlikte verilemez.
  final Widget Function(T data)? dataBuilder;

  /// Hata durumunda retry butonuna basıldığında çağrılır.
  /// `null` ise retry butonu gizli.
  final VoidCallback? onRetry;

  /// Hata mesajı (default: i18n `common.error`). Localized override için.
  final String? errorTitle;

  /// Loading widget override. `null` ise default `Center(CircularProgressIndicator)`.
  final Widget? loadingWidget;

  /// AppScaffold pass-through.
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;

  const BaseScaffold({
    super.key,
    this.appBar,
    this.body,
    this.asyncValue,
    this.dataBuilder,
    this.onRetry,
    this.errorTitle,
    this.loadingWidget,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
  })  : assert(
          body != null || asyncValue != null,
          'BaseScaffold: ya `body` ya da `asyncValue` verilmeli',
        ),
        assert(
          asyncValue == null || dataBuilder != null,
          'BaseScaffold: `asyncValue` verildiyse `dataBuilder` zorunlu',
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget effectiveBody;
    if (asyncValue != null) {
      effectiveBody = asyncValue!.when(
        loading: () =>
            loadingWidget ?? const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppEmptyState.error(
          title: errorTitle,
          description: err.toString(),
          onAction: onRetry,
        ),
        data: (data) => dataBuilder!(data),
      );
    } else {
      effectiveBody = body!;
    }

    return AppScaffold(
      appBar: appBar,
      body: effectiveBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
