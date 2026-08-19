class FirestoreConstants {
  FirestoreConstants._();

  // Collections
  static const String users = 'users';
  static const String products = 'products';
  static const String cart = 'cart';
  static const String orders = 'orders';
  static const String promoCodes = 'promoCodes';
  static const String notifications = 'notifications';
  static const String deliveryFees = 'deliveryFees';

  // User Fields
  static const String userId = 'userId';
  static const String email = 'email';
  static const String name = 'name';
  static const String phone = 'phone';

  // Product Fields
  static const String image = 'image';
  static const String price = 'price';
  static const String size = 'size';
  static const String quantity = 'quantity';

  // Order Fields
  static const String status = 'status';
  static const String total = 'total';
  static const String orderedAt = 'orderedAt';
  static const String deliveredAt = 'deliveredAt';
}