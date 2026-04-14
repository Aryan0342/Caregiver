import 'package:flutter/material.dart';

class ClientSessionController extends ChangeNotifier {
  String? _activeClientId;
  final Map<String, int> _clientProgress = <String, int>{};

  String? get activeClientId => _activeClientId;

  Map<String, int> get clientProgress =>
      Map<String, int>.unmodifiable(_clientProgress);

  int progressFor(String clientId) {
    return _clientProgress[clientId] ?? 0;
  }

  void setInitialClient(String clientId, {int index = 0}) {
    if (_activeClientId == null) {
      _activeClientId = clientId;
      _clientProgress[clientId] = index;
      notifyListeners();
    }
  }

  void activateClient(String clientId, {int index = 0}) {
    _activeClientId = clientId;
    _clientProgress[clientId] = index;
    notifyListeners();
  }

  void switchClient(String nextClientId, {required int currentIndex}) {
    if (_activeClientId != null) {
      _clientProgress[_activeClientId!] = currentIndex;
    }

    _activeClientId = nextClientId;
    _clientProgress.putIfAbsent(nextClientId, () => 0);
    notifyListeners();
  }

  void updateCurrentIndex(int currentIndex) {
    final activeId = _activeClientId;
    if (activeId == null) return;

    _clientProgress[activeId] = currentIndex;
    notifyListeners();
  }
}

class ClientSessionProvider extends InheritedNotifier<ClientSessionController> {
  const ClientSessionProvider({
    super.key,
    required ClientSessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static ClientSessionController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ClientSessionProvider>();
    if (provider?.notifier == null) {
      throw Exception('ClientSessionProvider not found in widget tree');
    }
    return provider!.notifier!;
  }
}
