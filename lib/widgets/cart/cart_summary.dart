import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;

  const CartSummary({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141118),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Subtotal",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
              Text(
                "${subtotal.toStringAsFixed(1)} EGP",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Discount",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                ),
              ),
              Text(
                "- ${discount.toStringAsFixed(1)} EGP",
                style: const TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(
            height: 35,
            color: Colors.white12,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${total.toStringAsFixed(1)} EGP",
                style: const TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}