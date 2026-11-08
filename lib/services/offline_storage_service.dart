import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  String _cartKey(String uid) => 'medlife_offline_cart_$uid';
  String _ordersKey(String uid) => 'medlife_pending_orders_$uid';

  Future<List<Map<String, dynamic>>> loadCart(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) { return []; }
  }

  Future<void> saveCart(String uid, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey(uid), jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> loadPendingOrders(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersKey(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) { return []; }
  }

  Future<void> addPendingOrder(String uid, Map<String, dynamic> order) async {
    final orders = await loadPendingOrders(uid);
    orders.removeWhere((item) => item['localId'] == order['localId']);
    orders.add(order);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey(uid), jsonEncode(orders));
  }

  Future<void> removePendingOrder(String uid, String localId) async {
    final orders = await loadPendingOrders(uid);
    orders.removeWhere((item) => item['localId'] == localId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ordersKey(uid), jsonEncode(orders));
  }
}