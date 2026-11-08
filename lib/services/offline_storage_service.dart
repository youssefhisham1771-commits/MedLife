import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  String _cartKey(String uid) => 'medlife_offline_cart_$uid';
  String _cartDirtyKey(String uid) => 'medlife_offline_cart_dirty_$uid';
  String _removedCartIdsKey(String uid) => 'medlife_removed_cart_ids_$uid';
  String _clearRemoteCartKey(String uid) => 'medlife_clear_remote_cart_$uid';
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

  Future<bool> isCartDirty(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cartDirtyKey(uid)) ?? false;
  }

  Future<void> setCartDirty(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cartDirtyKey(uid), value);
  }

  Future<List<String>> loadRemovedCartIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_removedCartIdsKey(uid)) ?? [];
  }

  Future<void> addRemovedCartId(String uid, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_removedCartIdsKey(uid)) ?? [];
    if (!ids.contains(id)) ids.add(id);
    await prefs.setStringList(_removedCartIdsKey(uid), ids);
  }

  Future<void> clearRemovedCartIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_removedCartIdsKey(uid));
  }

  Future<bool> shouldClearRemoteCart(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_clearRemoteCartKey(uid)) ?? false;
  }

  Future<void> setClearRemoteCart(String uid, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_clearRemoteCartKey(uid), value);
  }

  String _profileKey(String uid) => 'medlife_saved_profile_$uid';
  String _addressesKey(String uid) => 'medlife_saved_addresses_$uid';
  String _feesKey(String uid) => 'medlife_delivery_fees_$uid';

  Future<void> saveAddresses(String uid, List<Map<String, dynamic>> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressesKey(uid), jsonEncode(addresses));
  }

  Future<List<Map<String, dynamic>>> loadAddresses(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) { return []; }
  }

  Future<void> saveDeliveryFee(String uid, String governorate, double fee) async {
    final prefs = await SharedPreferences.getInstance();
    final fees = Map<String, double>.from(
      (jsonDecode(prefs.getString(_feesKey(uid)) ?? '{}') as Map).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
    fees[governorate] = fee;
    await prefs.setString(_feesKey(uid), jsonEncode(fees));
  }

  Future<double?> loadDeliveryFee(String uid, String governorate) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final fees = jsonDecode(prefs.getString(_feesKey(uid)) ?? '{}') as Map;
      final value = fees[governorate];
      return value is num ? value.toDouble() : null;
    } catch (_) { return null; }
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