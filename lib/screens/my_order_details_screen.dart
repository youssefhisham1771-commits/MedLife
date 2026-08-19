import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MyOrderDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot order;

  const MyOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final data = order.data() as Map<String, dynamic>;

    List items = data['items'] ?? [];

    double subtotal = 0;

    for (final item in items) {
      final quantity =
          int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

      final price =
          double.tryParse(item['price']?.toString() ?? '0') ?? 0;

      subtotal += price * quantity;
    }

    final shipping =
        double.tryParse(data['shipping']?.toString() ?? '0') ?? 0;

    final total =
        double.tryParse(data['total']?.toString() ?? '0') ??
            (subtotal + shipping);

    return Scaffold(
      backgroundColor: const Color(0xFF070B1A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF070B1A),
        elevation: 0,
        title: const Text("My Order Details"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0D1225),
                Color(0xFF061A42),
                Color(0xFF0D1225),
              ],
            ),
          ),

          child: Column(
            children: [

              /// المنتجات
              ...items.map((item) {

                int qty = item['quantity'] ?? 1;

                double price =
    double.tryParse(item['price'].toString()) ?? 0;

                double total =
                    price * qty;

                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 18,
                  ),

                  padding: const EdgeInsets.all(14),

                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .05),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),

                  child: Row(
                    children: [

                      /// الصورة
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),

                        child: Image.network(
                          item['image'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Size: ${item['size']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "${price.toStringAsFixed(0)} EGP",
                              style: const TextStyle(
                                color: Color(0xFF6EA6C1),
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              "x$qty",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "${total.toStringAsFixed(0)} EGP",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const Divider(
                color: Colors.white24,
                height: 40,
              ),

              _priceRow(
                "Subtotal",
                subtotal,
              ),

              const SizedBox(height: 10),

              _priceRow(
                "Shipping",
                shipping,
              ),

              const Divider(
                color: Colors.white24,
                height: 30,
              ),

              _priceRow(
                "Total Amount",
                total,
                isTotal: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRow(
    String title,
    double value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal
                ? Colors.white
                : Colors.white70,
            fontSize: isTotal ? 24 : 17,
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
        Text(
          "${value.toStringAsFixed(2)} EGP",
          style: TextStyle(
            color: isTotal
                ? const Color(0xFF6EA6C1)
                : Colors.white70,
            fontSize: isTotal ? 28 : 17,
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}