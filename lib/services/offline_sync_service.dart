import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';
import 'order_service.dart';

class OfflineSyncService {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  StreamSubscription<User?>? _auth;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _connectivity = Connectivity().onConnectivityChanged.listen((states) {
      if (states.any((x) => x != ConnectivityResult.none)) syncNow();
    });
    _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) syncNow();
    });
    await syncNow();
  }

  Future<void> syncNow() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await CartService().syncCart();
    await OrderService().syncPendingOrders();
  }

  Future<void> dispose() async {
    await _connectivity?.cancel();
    await _auth?.cancel();
    _connectivity = null;
    _auth = null;
    _started = false;
  }
}