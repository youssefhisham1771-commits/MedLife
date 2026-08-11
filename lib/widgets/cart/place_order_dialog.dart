import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/order_service.dart';
import 'order_success_dialog.dart';

class PlaceOrderDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  final VoidCallback onOrderPlaced;

  const PlaceOrderDialog({
    super.key,
    required this.cart,
    required this.total,
    required this.onOrderPlaced,
  });

  @override
  State<PlaceOrderDialog> createState() =>
      _PlaceOrderDialogState();
}

class _PlaceOrderDialogState extends State<PlaceOrderDialog> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final OrderService _orderService = OrderService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

Future<void> _submitOrder() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await _orderService.placeOrder(
    name: _nameController.text.trim(),
    phone: _phoneController.text.trim(),
    cart: widget.cart,
    total: widget.total,
  );

  if (!mounted) return;

  widget.onOrderPlaced();

  Navigator.pop(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const OrderSuccessDialog(),
  );
}
@override
Widget build(BuildContext context) {
    return AlertDialog(
  backgroundColor: const Color(0xFF141118),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  title: const Text(
    "Enter your data",
    style: TextStyle(color: Colors.white),
  ),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: "Name",
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      const SizedBox(height: 15),
      TextField(
        controller: _phoneController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: "Phone",
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
    ],
  ),
  actions: [
  TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    child: const Text(
      "Cancel",
      style: TextStyle(
        color: Colors.white70,
      ),
    ),
  ),
  TextButton(
    onPressed: _submitOrder,
    child: const Text(
      "Confirm",
      style: TextStyle(
        color: Color(0xFF6EA6C1),
      ),
    ),
  ),
],
);
}
}