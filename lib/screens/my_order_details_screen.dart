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

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${data['total']} EGP",
                    style: const TextStyle(
                      color: Color(0xFF6EA6C1),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}