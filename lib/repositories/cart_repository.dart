import '../services/cart_service.dart';

class CartRepository {
  final CartService _cartService = CartService();

  Future<List<Map<String, dynamic>>> loadCart() {
    return _cartService.loadCart();
  }

  Future<void> updateQuantity(
    String docId,
    int quantity,
  ) {
    return _cartService.updateQuantity(
      docId,
      quantity,
    );
  }

  Future<void> removeItem(String docId) {
    return _cartService.removeItem(docId);
  }
}