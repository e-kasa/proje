import 'dart:async';

/// ApiClient → AuthNotifier arası circular dependency'yi kırar.
/// ApiClient 401 alınca [notifyUnauthorized] çağırır.
/// AuthNotifier başlarken [onUnauthorized] stream'ini dinler.
class AuthEvents {
  AuthEvents._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get onUnauthorized => _controller.stream;

  static void notifyUnauthorized() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
