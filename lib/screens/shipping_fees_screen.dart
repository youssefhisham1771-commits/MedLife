import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShippingFeesScreen extends StatefulWidget {
  const ShippingFeesScreen({super.key});

  @override
  State<ShippingFeesScreen> createState() => _ShippingFeesScreenState();
}

class _ShippingFeesScreenState extends State<ShippingFeesScreen> {
  static const List<String> egyptGovernorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  bool _checkingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _checkingAdmin = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final role = data?['role']?.toString().toLowerCase().trim();

      if (!mounted) return;

      setState(() {
        _isAdmin = role == 'admin';
        _checkingAdmin = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingAdmin = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _showFeeDialog({
    required String governorate,
    double? currentFee,
  }) async {
    final controller = TextEditingController(
      text: currentFee == null
          ? ''
          : currentFee.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        final isEditing = currentFee != null;

        return AlertDialog(
          backgroundColor: const Color(0xFF1D1B20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF6EA6C1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Edit Shipping Fee'
                      : 'Set Shipping Fee',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                governorate,
                style: const TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Shipping fee',
                  hintText: 'e.g. 25',
                  suffixText: 'EGP',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6EA6C1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter 0 if delivery is free in this governorate.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6EA6C1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                final value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );

                if (value == null || value < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid shipping fee.',
                      ),
                    ),
                  );
                  return;
                }

                // Dismiss the keyboard before closing the dialog.
                // This prevents Flutter's Overlay/InheritedElement assertion
                // when the dialog is popped while the TextField is focused.
                FocusScope.of(dialogContext).unfocus();

                Future<void>.delayed(
                  const Duration(milliseconds: 150),
                  () {
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(value);
                  },
                );
              },
              child: Text(isEditing ? 'Save Changes' : 'Save Fee'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('deliveryFees')
          .doc(governorate)
          .set({
        'governorate': governorate,
        'fee': result,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$governorate shipping fee saved successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save the shipping fee. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteFee(String governorate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1B20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Shipping Fee?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'The shipping fee for $governorate will be removed.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('deliveryFees')
          .doc(governorate)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipping fee deleted.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete the shipping fee. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return const Scaffold(
        backgroundColor: Color(0xFF141118),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6EA6C1),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF141118),
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Shipping Fees'),
        ),
        body: const Center(
          child: Text(
            'Access denied.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF141118),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Shipping Fees',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('deliveryFees')
            .snapshots(),
        builder: (context, snapshot) {
          final fees = <String, double>{};

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data();
              final governorate =
                  data['governorate']?.toString() ?? doc.id;
              final fee = _parseDouble(data['fee']);

              if (governorate.isNotEmpty && fee != null) {
                fees[governorate] = fee;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2D5A74),
                      Color(0xFF123249),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF6EA6C1),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Fees by Governorate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Set the delivery price for every governorate. The selected address fee will be added automatically to the order total.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Egypt Governorates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${fees.length}/${egyptGovernorates.length} set',
                    style: const TextStyle(
                      color: Color(0xFF6EA6C1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...egyptGovernorates.map((governorate) {
                final fee = fees[governorate];
                final configured = fee != null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1B20),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: configured
                          ? const Color(0xFF6EA6C1).withOpacity(.25)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6EA6C1).withOpacity(.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          color: Color(0xFF6EA6C1),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              governorate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              configured
                                  ? '${fee.toStringAsFixed(2)} EGP'
                                  : 'Not set yet',
                              style: TextStyle(
                                color: configured
                                    ? const Color(0xFF6EA6C1)
                                    : Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: configured ? 'Edit' : 'Set fee',
                        onPressed: () => _showFeeDialog(
                          governorate: governorate,
                          currentFee: fee,
                        ),
                        icon: Icon(
                          configured
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline,
                          color: const Color(0xFF6EA6C1),
                        ),
                      ),
                      if (configured)
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _deleteFee(governorate),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
