import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aynı route'a ikinci tıklandığında ekranların servis çağrısı yapmasını sağlar.
/// GoRouter aynı route'a go() ile gidince widget rebuild etmez,
/// bu provider ile ekranlar dinleyip kendi veri yüklemelerini tetikler.
typedef NavRefreshState = ({String route, int version});

class NavigationRefreshNotifier extends StateNotifier<NavRefreshState> {
  NavigationRefreshNotifier() : super((route: '', version: 0));

  void refresh(String route) {
    state = (route: route, version: state.version + 1);
  }
}

final navigationRefreshProvider =
    StateNotifierProvider<NavigationRefreshNotifier, NavRefreshState>(
  (ref) => NavigationRefreshNotifier(),
);
