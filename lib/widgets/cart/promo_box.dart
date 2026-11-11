import 'package:flutter/material.dart';

class PromoBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;

  const PromoBox({
    super.key,
    required this.controller,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Enter Promo Code",
          hintStyle: const TextStyle(
            color: Colors.white38,
          ),
          prefixIcon: const Icon(
            Icons.discount_outlined,
            color: Colors.white38,
          ),
          suffixIcon: TextButton(
            onPressed: onApply,
            child: const Text(
              "Apply",
              style: TextStyle(
                color: Color(0xFF6EA6C1),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}