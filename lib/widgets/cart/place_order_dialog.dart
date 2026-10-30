import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/order_service.dart';
import '../../services/delivery_fee_service.dart';
import '../../screens/my_addresses_screen.dart';
import 'order_success_dialog.dart';

class PlaceOrderDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final double total;
  final double discount;
  final VoidCallback onOrderPlaced;

  const PlaceOrderDialog({
    super.key,
    required this.cart,
    required this.total,
    required this.discount,
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

  final DeliveryFeeService _deliveryFeeService =
      DeliveryFeeService();

  List<Map<String, dynamic>> addresses = [];

  String? selectedAddressId;

  bool isLoadingAddresses = true;
  bool isSubmitting = false;

  double shipping = 0;
  bool isLoadingShipping = false;

  @override
  void initState() {
    super.initState();

    _loadUserData();
    _loadAddresses();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        _nameController.text =
            data?['name']?.toString() ?? '';

        _phoneController.text =
            data?['phone']?.toString() ?? '';
      }
    } catch (_) {
      // لا نوقف عملية الطلب بسبب فشل تحميل البيانات.
    }
  }

  Future<void> _loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoadingAddresses = false;
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      final loadedAddresses = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
  'id': doc.id,
  'title': data['title'] ?? '',
  'governorate':
      data['governorate'] ?? '',
  'address': data['address'] ?? '',
};
      }).toList();

      if (!mounted) return;

      setState(() {
        addresses = loadedAddresses;
        isLoadingAddresses = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingAddresses = false;
      });
    }
  }

  Future<void> _loadShippingForAddress(
    String addressId,
  ) async {
    final address = addresses.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id'] == addressId,
          orElse: () => null,
        );

    if (address == null) {
      if (!mounted) return;

      setState(() {
        shipping = 0;
        isLoadingShipping = false;
      });
      return;
    }

    final governorate =
        address['governorate']?.toString().trim() ?? '';

    if (governorate.isEmpty) {
      if (!mounted) return;

      setState(() {
        shipping = 0;
        isLoadingShipping = false;
      });
      return;
    }

    try {
      final fee =
          await _deliveryFeeService.getFee(governorate);

      if (!mounted || selectedAddressId != addressId) {
        return;
      }

      setState(() {
        shipping = fee;
        isLoadingShipping = false;
      });
    } catch (_) {
      if (!mounted || selectedAddressId != addressId) {
        return;
      }

      setState(() {
        shipping = 0;
        isLoadingShipping = false;
      });

      _showMessage(
        "Could not load the delivery fee. Please try again.",
      );
    }
  }

  Future<void> _addAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyAddressesScreen(),
      ),
    );

    if (!mounted) return;

    await _loadAddresses();
  }

  Map<String, dynamic>? get selectedAddress {
    if (selectedAddressId == null) return null;

    try {
      return addresses.firstWhere(
        (address) =>
            address['id'] == selectedAddressId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitOrder() async {
    if (isSubmitting) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage("Please enter your name.");
      return;
    }

    if (phone.isEmpty) {
      _showMessage("Please enter your phone number.");
      return;
    }

    if (selectedAddress == null) {
      _showMessage("Please select a delivery address.");
      return;
    }

    if (isLoadingShipping) {
      _showMessage("Please wait while the shipping fee is loading.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage("Please login first.");
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _orderService.placeOrder(
        name: name,
        phone: phone,
        addressTitle:
            selectedAddress!['title'].toString(),
        governorate:
    selectedAddress!['governorate']
        .toString(),
        address:
            selectedAddress!['address'].toString(),
        cart: widget.cart,
        total: widget.total + shipping,
        shipping: shipping,
        discount: widget.discount,
      );

      if (!mounted) return;

      widget.onOrderPlaced();

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const OrderSuccessDialog(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showMessage(
        "Failed to place order. Please try again.",
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
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
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  labelText: "Phone",
                  labelStyle: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Address",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (isLoadingAddresses)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6EA6C1),
                  ),
                )
              else if (addresses.isEmpty)
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.05),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white12,
                        ),
                      ),
                      child: const Text(
                        "You don't have any saved address.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildAddAddressButton(),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.05),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white12,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAddressId,
                          isExpanded: true,
                          dropdownColor:
                              const Color(0xFF1D1B20),
                          hint: const Text(
                            "Choose a saved address",
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                          items: addresses.map((address) {
                            return DropdownMenuItem<String>(
                              value: address['id'],
                              child: Text(
                                address['title']
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value == null) return;

                            setState(() {
                              selectedAddressId = value;
                              shipping = 0;
                              isLoadingShipping = true;
                            });

                            await _loadShippingForAddress(value);
                          },
                        ),
                      ),
                    ),

                    if (selectedAddress != null) ...[
                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6EA6C1)
                              .withOpacity(.10),
                          borderRadius:
                              BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(
                              0xFF6EA6C1,
                            ).withOpacity(.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color:
                                  Color(0xFF6EA6C1),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedAddress!['governorate']
                                        .toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF6EA6C1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    selectedAddress!['address']
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (selectedAddress != null) ...[
                      const SizedBox(height: 14),

                      _buildOrderSummary(),
                    ],

                    if (addresses.length < 3) ...[
                      const SizedBox(height: 10),
                      _buildAddAddressButton(),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting
              ? null
              : () {
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
          onPressed:
              isSubmitting ? null : _submitOrder,
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6EA6C1),
                  ),
                )
              : const Text(
                  "Confirm",
                  style: TextStyle(
                    color: Color(0xFF6EA6C1),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = 0;

    for (final item in widget.cart) {
      final price =
          double.tryParse(item['price'].toString()) ?? 0;

      final quantity =
          int.tryParse(item['quantity'].toString()) ?? 1;

      subtotal += price * quantity;
    }

    final grandTotal =
        subtotal - widget.discount + shipping;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            "Subtotal",
            subtotal,
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Shipping",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              if (isLoadingShipping)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6EA6C1),
                  ),
                )
              else
                Text(
                  "${shipping.toStringAsFixed(2)} EGP",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          _buildPriceRow(
            "Discount",
            -widget.discount,
          ),

          const Divider(
            color: Colors.white12,
            height: 26,
          ),

          _buildPriceRow(
            "Total",
            grandTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
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
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          "${value.toStringAsFixed(2)} EGP",
          style: TextStyle(
            color: isTotal
                ? const Color(0xFF6EA6C1)
                : Colors.white70,
            fontSize: isTotal ? 22 : 16,
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAddAddressButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _addAddress,
        icon: const Icon(
          Icons.add,
          color: Color(0xFF6EA6C1),
        ),
        label: const Text(
          "Add Address",
          style: TextStyle(
            color: Color(0xFF6EA6C1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}