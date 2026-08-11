class CartItemModel {
  final String? docId;
  final String name;
  final String image;
  final double price;
  final String size;
  final int quantity;

  const CartItemModel({
    this.docId,
    required this.name,
    required this.image,
    required this.price,
    required this.size,
    required this.quantity,
  });

  factory CartItemModel.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    return CartItemModel(
      docId: docId,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'size': size,
      'quantity': quantity,
    };
  }

  CartItemModel copyWith({
    String? docId,
    String? name,
    String? image,
    double? price,
    String? size,
    int? quantity,
  }) {
    return CartItemModel(
      docId: docId ?? this.docId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
    );
  }
}