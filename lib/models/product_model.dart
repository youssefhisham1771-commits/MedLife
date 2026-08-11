class ProductModel {
  final String id;
  final String name;
  final String image;
  final double price;
  final String category;
  final String description;
  final List<String> sizes;

  const ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
    required this.description,
    required this.sizes,
  });

  factory ProductModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      sizes: List<String>.from(map['sizes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'price': price,
      'category': category,
      'description': description,
      'sizes': sizes,
    };
  }
}