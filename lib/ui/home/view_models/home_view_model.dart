import "package:flutter/foundation.dart";

class HomeViewModel extends ChangeNotifier {
  HomeViewModel() {
    refresh();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
  }
}
