import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/delivery_fee_service.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({super.key});

  @override
  State<MyAddressesScreen> createState() =>
      _MyAddressesScreenState();
}

class _MyAddressesScreenState
    extends State<MyAddressesScreen> {

  final List<Map<String, dynamic>> addresses = [];

  bool isLoading = true;

  bool isAdmin = false;
  bool isLoadingFees = true;

  Map<String, double> deliveryFees = {};

  String? selectedDeliveryGovernorate;

  final TextEditingController _deliveryFeeController =
      TextEditingController();

  final DeliveryFeeService _deliveryFeeService =
      DeliveryFeeService();

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

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _checkAdmin();
  }

  /// 🔥 LOAD ADDRESSES INSTANTLY
  Future<void> _loadAddresses() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    addresses.clear();

    for (var doc in snapshot.docs) {

      addresses.add({
  "id": doc.id,
  "title": doc['title'] ?? '',
  "governorate": doc['governorate'] ?? '',
  "address": doc['address'] ?? '',
});
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        isAdmin = false;
        isLoadingFees = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final admin =
          doc.exists && (doc.data()?['role'] ?? '') == 'admin';

      setState(() {
        isAdmin = admin;
        isLoadingFees = admin;
      });

      if (admin) {
        await _loadDeliveryFees();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isAdmin = false;
        isLoadingFees = false;
      });
    }
  }

  Future<void> _loadDeliveryFees() async {
    try {
      final fees = await _deliveryFeeService.getAllFees();

      if (!mounted) return;

      setState(() {
        deliveryFees = fees;
        isLoadingFees = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingFees = false;
      });
    }
  }

  Future<void> _saveDeliveryFee() async {
    final governorate = selectedDeliveryGovernorate;

    if (governorate == null || governorate.isEmpty) {
      _showMessage("Please select a governorate.");
      return;
    }

    final fee =
        double.tryParse(_deliveryFeeController.text.trim());

    if (fee == null || fee < 0) {
      _showMessage("Please enter a valid delivery fee.");
      return;
    }

    try {
      await _deliveryFeeService.saveFee(
        governorate: governorate,
        fee: fee,
      );

      if (!mounted) return;

      setState(() {
        deliveryFees[governorate] = fee;
        selectedDeliveryGovernorate = null;
        _deliveryFeeController.clear();
      });

      _showMessage("Delivery fee saved successfully.");
    } catch (_) {
      _showMessage(
        "Failed to save delivery fee. Please try again.",
      );
    }
  }

  Future<void> _deleteDeliveryFee(String governorate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1B20),
          title: const Text(
            "Delete delivery fee?",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Remove the delivery fee for $governorate?",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _deliveryFeeService.deleteFee(governorate);

      if (!mounted) return;

      setState(() {
        deliveryFees.remove(governorate);

        if (selectedDeliveryGovernorate == governorate) {
          selectedDeliveryGovernorate = null;
          _deliveryFeeController.clear();
        }
      });

      _showMessage("Delivery fee deleted.");
    } catch (_) {
      _showMessage(
        "Failed to delete delivery fee. Please try again.",
      );
    }
  }

  Future<void> _editDeliveryFee(
    String governorate,
    double currentFee,
  ) async {
    final controller = TextEditingController(
      text: currentFee.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1B20),
          title: Text(
            "Edit $governorate",
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Delivery Fee",
              suffixText: "EGP",
              labelStyle: TextStyle(color: Colors.white70),
              suffixStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final value =
                    double.tryParse(controller.text.trim());

                if (value == null || value < 0) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Color(0xFF6EA6C1),
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) return;

    try {
      await _deliveryFeeService.saveFee(
        governorate: governorate,
        fee: result,
      );

      if (!mounted) return;

      setState(() {
        deliveryFees[governorate] = result;

        if (selectedDeliveryGovernorate == governorate) {
          _deliveryFeeController.text =
              result.toStringAsFixed(2);
        }
      });

      _showMessage("Delivery fee updated successfully.");
    } catch (_) {
      _showMessage(
        "Failed to update delivery fee. Please try again.",
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDeliveryFeesContent() {
    final entries = deliveryFees.entries.toList()
      ..sort(
        (a, b) => egyptGovernorates
            .indexOf(a.key)
            .compareTo(egyptGovernorates.indexOf(b.key)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Delivery Fees by Governorate",
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Set delivery fees for each governorate",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;

            final governorateField =
                DropdownButtonFormField<String>(
              value: selectedDeliveryGovernorate,
              isExpanded: true,
              dropdownColor: const Color(0xFF1D1B20),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: "Select governorate",
                hintStyle: const TextStyle(
                  color: Colors.white70,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.white30,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF6EA6C1),
                  ),
                ),
              ),
              items: egyptGovernorates.map((governorate) {
                final alreadyAdded =
                    deliveryFees.containsKey(governorate);

                return DropdownMenuItem<String>(
                  value: governorate,
                  child: Text(
                    alreadyAdded
                        ? "$governorate ✓"
                        : governorate,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedDeliveryGovernorate = value;

                  final existing = deliveryFees[value];

                  _deliveryFeeController.text =
                      existing == null
                          ? ""
                          : existing.toStringAsFixed(2);
                });
              },
            );

            final feeField = TextField(
              controller: _deliveryFeeController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: const TextStyle(
                  color: Colors.white70,
                ),
                suffixText: "EGP",
                suffixStyle: const TextStyle(
                  color: Colors.white70,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.white30,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF6EA6C1),
                  ),
                ),
              ),
            );

            final addButton = SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saveDeliveryFee,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF6EA6C1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );

            if (narrow) {
              return Column(
                children: [
                  governorateField,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: feeField),
                      const SizedBox(width: 10),
                      addButton,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: governorateField),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: feeField),
                const SizedBox(width: 10),
                addButton,
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        if (isLoadingFees)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                color: Color(0xFF6EA6C1),
              ),
            ),
          )
        else if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "No delivery fees added yet.",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          )
        else
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: Column(
              children: entries.map((entry) {
                return _buildDeliveryFeeRow(
                  entry.key,
                  entry.value,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryFeeRow(
    String governorate,
    double fee,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              governorate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),

          Text(
            "${fee.toStringAsFixed(2)} EGP",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),

          const SizedBox(width: 6),

          IconButton(
            tooltip: "Edit",
            onPressed: () =>
                _editDeliveryFee(governorate, fee),
            icon: const Icon(
              Icons.edit,
              color: Color(0xFF6EA6C1),
              size: 22,
            ),
          ),

          IconButton(
            tooltip: "Delete",
            onPressed: () =>
                _deleteDeliveryFee(governorate),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {

    if (addresses.length >= 3) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Maximum 3 addresses allowed"),
        ),
      );

      return;
    }

    final titleController =
        TextEditingController();

        String? selectedGovernorate;

    final addressController =
        TextEditingController();

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor:
          const Color(0xFF1D1B20),

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),

      builder: (context) {

        return Padding(

          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                24,
          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Container(
                width: 70,
                height: 5,

                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: .4),

                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Add New Address",

                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              TextField(

                controller: titleController,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: InputDecoration(

                  labelText: "Title",

                  labelStyle: const TextStyle(
                    color: Colors.white70,
                  ),

                  hintText:
                      "Home / Work / University",

                  hintStyle: const TextStyle(
                    color: Colors.white38,
                  ),

                  prefixIcon: const Icon(
                    Icons.title,
                    color: Color(0xFF6EA6C1),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),

                    borderSide:
                        const BorderSide(
                      color: Color(0xFF6EA6C1),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              const SizedBox(height: 18),

// ===============================
// GOVERNORATE
// ===============================

InkWell(
  onTap: () async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1B20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return _GovernoratePicker(
          governorates: egyptGovernorates,
          selectedGovernorate: selectedGovernorate,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        selectedGovernorate = result;
      });
    }
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFF6EA6C1),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.account_balance_outlined,
          color: Color(0xFF6EA6C1),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "Governorate",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                selectedGovernorate ??
                    "Select your governorate",
                style: TextStyle(
                  color: selectedGovernorate == null
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white70,
        ),
      ],
    ),
  ),
),

const SizedBox(height: 18),

// ===============================
// ADDRESS DETAILS
// ===============================

TextField(
  controller: addressController,
  maxLines: 3,
  style: const TextStyle(
    color: Colors.white,
  ),
  decoration: InputDecoration(
    labelText: "Address Details",
    labelStyle: const TextStyle(
      color: Colors.white70,
    ),
    hintText:
        "Street, Area, Building, Floor, Apartment...",
    hintStyle: const TextStyle(
      color: Colors.white38,
    ),
    prefixIcon: const Padding(
      padding: EdgeInsets.only(
        bottom: 50,
      ),
      child: Icon(
        Icons.location_on,
        color: Color(0xFF6EA6C1),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFF6EA6C1),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius:
          BorderRadius.circular(18),
      borderSide: const BorderSide(
        color: Color(0xFF6EA6C1),
        width: 2,
      ),
    ),
  ),
),

              const SizedBox(height: 24),

              SizedBox(

                width: double.infinity,
                height: 56,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                        const Color(0xFF6EA6C1),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                    ),
                  ),

                  onPressed: () async {

                    if (titleController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please enter an address title."),
    ),
  );
  return;
}

if (selectedGovernorate == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please select your governorate."),
    ),
  );
  return;
}

if (addressController.text.trim().isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please enter your address details."),
    ),
  );
  return;
}

                    final user =
                        FirebaseAuth.instance
                            .currentUser;

                    if (user == null) return;

                    final newAddress = {
  "title": titleController.text.trim(),

  "governorate":
      selectedGovernorate!,

  "address":
      addressController.text.trim(),
};

                    try {
                      final doc =
                          await FirebaseFirestore
                              .instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('addresses')
                              .add(newAddress);

                      if (!mounted) return;

                      setState(() {
                        addresses.add({
                          "id": doc.id,
                          ...newAddress,
                        });
                      });

                      Navigator.pop(context);
                    } catch (_) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Failed to save address. Please try again.",
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text(

                    "Save Address",

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteAddress(int index) async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final addressId =
        addresses[index]["id"];

    /// 🔥 DELETE INSTANTLY
    setState(() {
      addresses.removeAt(index);
    });

    if (addressId != null &&
        addressId.toString().isNotEmpty) {

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    }
  }

  IconData _getAddressIcon(String title) {

    switch (title.toLowerCase()) {

      case "home":
        return Icons.home_outlined;

      case "work":
        return Icons.work_outline;

      case "university":
        return Icons.school_outlined;

      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    const Color bgColor =
        Color(0xFF141118);

    const Color cardColor =
        Color(0xFF1D1B20);

    const Color mainText =
        Colors.white;

    const Color subText =
        Colors.white70;

    const Color blue =
        Color(0xFF6EA6C1);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor:
            const Color(0xFF141118),

        elevation: 0,

        leading: IconButton(

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(

          "My Addresses",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
            fontSize: 30,
          ),
        ),

        actions: [

          if (addresses.length < 3)

            TextButton.icon(

              onPressed:
                  _showAddAddressDialog,

              icon: const Icon(
                Icons.add,
                color: blue,
              ),

              label: const Text(

                "Add",

                style: TextStyle(
                  color: blue,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton:
          addresses.isNotEmpty &&
                  addresses.length < 3

              ? FloatingActionButton.extended(

                backgroundColor: blue,

                onPressed:
                    _showAddAddressDialog,

                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),

                label: const Text(

                  "Add Address",

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              )

              : null,

      body:
          isLoading

              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: blue,
                  ),
                )

              : SingleChildScrollView(

                padding:
                    const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    /// TOP CARD + ADMIN DELIVERY FEES
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(24),
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF1D1B20),
                            Color(0xFF141118),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: blue.withValues(
                                    alpha: .15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: blue,
                                  size: 36,
                                ),
                              ),

                              const SizedBox(width: 18),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Manage your addresses",
                                      style: TextStyle(
                                        color: mainText,
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "You can add up to 3 addresses",
                                      style: TextStyle(
                                        color: subText,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: blue.withValues(
                                    alpha: .15,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: Text(
                                  "${addresses.length}/3",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (isAdmin) ...[
                            const SizedBox(height: 24),

                            Divider(
                              color: Colors.white
                                  .withValues(alpha: .08),
                              height: 1,
                            ),

                            const SizedBox(height: 22),

                            _buildDeliveryFeesContent(),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(

                      "Your Addresses",

                      style: TextStyle(
                        color: mainText,
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (addresses.isEmpty)

                      Container(

                        width: double.infinity,

                        padding:
                            const EdgeInsets.all(
                              30,
                            ),

                        decoration: BoxDecoration(
                          color: cardColor,

                          borderRadius:
                              BorderRadius.circular(
                                28,
                              ),
                        ),

                        child: Column(
                          children: [

                            Container(

                              width: 90,
                              height: 90,

                              decoration:
                                  BoxDecoration(
                                color:
                                    blue.withValues(alpha: 
                                      .15,
                                    ),

                                shape:
                                    BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons
                                    .location_off_outlined,

                                color: blue,
                                size: 45,
                              ),
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            const Text(

                              "No Addresses Yet",

                              style: TextStyle(
                                color:
                                    mainText,

                                fontSize: 24,

                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            const Text(

                              "Add your first address to make ordering faster and easier.",

                              textAlign:
                                  TextAlign.center,

                              style: TextStyle(
                                color:
                                    subText,

                                fontSize:
                                    15,

                                height:
                                    1.5,
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            SizedBox(

                              width:
                                  double.infinity,

                              height: 56,

                              child:
                                  ElevatedButton.icon(

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          blue,

                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                              18,
                                            ),
                                      ),
                                    ),

                                    onPressed:
                                        _showAddAddressDialog,

                                    icon:
                                        const Icon(
                                      Icons.add,
                                      color:
                                          Colors
                                              .white,
                                    ),

                                    label:
                                        const Text(

                                          "Add Address",

                                          style:
                                              TextStyle(
                                            color:
                                                Colors
                                                    .white,

                                            fontWeight:
                                                FontWeight.bold,

                                            fontSize:
                                                18,
                                          ),
                                        ),
                                  ),
                            ),
                          ],
                        ),
                      ),

                    ...List.generate(
                      addresses.length,

                      (index) {

                        final item =
                            addresses[index];

                        return Padding(

                          padding:
                              const EdgeInsets.only(
                                bottom: 18,
                              ),

                          child: Container(

                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets.all(
                                  18,
                                ),

                            decoration:
                                BoxDecoration(
                              color: cardColor,

                              borderRadius:
                                  BorderRadius.circular(
                                    28,
                                  ),
                            ),

                            child: Row(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Container(

                                  width: 70,
                                  height: 70,

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        blue.withValues(alpha: 
                                          .15,
                                        ),

                                    borderRadius:
                                        BorderRadius.circular(
                                          22,
                                        ),
                                  ),

                                  child: Icon(

                                    _getAddressIcon(
                                      item['title'],
                                    ),

                                    color: blue,
                                    size: 34,
                                  ),
                                ),

                                const SizedBox(
                                  width: 16,
                                ),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Row(
                                        children: [

                                          Text(

                                            item['title'],

                                            style:
                                                const TextStyle(
                                              color:
                                                  mainText,

                                              fontSize:
                                                  24,

                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(
                                            width:
                                                10,
                                          ),

                                          if (index ==
                                              0)

                                            Container(

                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        12,

                                                    vertical:
                                                        6,
                                                  ),

                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    blue.withValues(alpha: 
                                                      .15,
                                                    ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                      14,
                                                    ),
                                              ),

                                              child:
                                                  const Text(

                                                    "Default",

                                                    style:
                                                        TextStyle(
                                                      color:
                                                          blue,

                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),

                                      Text(
  item['governorate'] ?? '',
  style: const TextStyle(
    color: blue,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 4),

Text(
  item['address'] ?? '',
  style: const TextStyle(
    color: subText,
    fontSize: 16,
    height: 1.5,
  ),
),
                                    ],
                                  ),
                                ),

                                PopupMenuButton(

                                  color:
                                      cardColor,

                                  icon: const Icon(
                                    Icons.more_vert,
                                    color:
                                        subText,
                                  ),

                                  itemBuilder:
                                      (context) => [

                                        PopupMenuItem(

                                          onTap: () {

                                            Future.delayed(
                                              Duration
                                                  .zero,

                                              () {

                                                _deleteAddress(
                                                  index,
                                                );
                                              },
                                            );
                                          },

                                          child:
                                              const Row(
                                                children: [

                                                  Icon(
                                                    Icons
                                                        .delete,

                                                    color:
                                                        Colors.red,
                                                  ),

                                                  SizedBox(
                                                    width:
                                                        10,
                                                  ),

                                                  Text(
                                                    "Delete",
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Container(

                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                            20,
                          ),

                      decoration: BoxDecoration(
                        color: cardColor,

                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                      ),

                      child: Row(
                        children: [

                          Container(

                            width: 55,
                            height: 55,

                            decoration:
                                BoxDecoration(
                              color:
                                  blue.withValues(alpha: 
                                    .15,
                                  ),

                              borderRadius:
                                  BorderRadius.circular(
                                    18,
                                  ),
                            ),

                            child: const Icon(
                              Icons.shield_outlined,
                              color: blue,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          const Expanded(

                            child: Text(

                              "Your addresses are saved securely and used to deliver your orders.",

                              style: TextStyle(
                                color: subText,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
    );
  }
}

class _GovernoratePicker extends StatefulWidget {
final List<String> governorates;
final String? selectedGovernorate;

const _GovernoratePicker({
  required this.governorates,
  required this.selectedGovernorate,
});

@override
State<_GovernoratePicker> createState() =>
    _GovernoratePickerState();
}

class _GovernoratePickerState
  extends State<_GovernoratePicker> {
final TextEditingController searchController =
    TextEditingController();

late List<String> filteredGovernorates;

@override
void initState() {
  super.initState();

  filteredGovernorates =
      List.from(widget.governorates);

  searchController.addListener(_filter);
}

void _filter() {
  final query =
      searchController.text.trim().toLowerCase();

  setState(() {
    filteredGovernorates =
        widget.governorates.where((governorate) {
      return governorate
          .toLowerCase()
          .contains(query);
    }).toList();
  });
}

@override
void dispose() {
  searchController.removeListener(_filter);
  searchController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Select Governorate",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: searchController,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText:
                  "Search governorate",
              hintStyle: const TextStyle(
                color: Colors.white54,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white54,
              ),
              filled: true,
              fillColor:
                  Colors.white.withOpacity(.05),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  filteredGovernorates.length,
              itemBuilder: (context, index) {
                final governorate =
                    filteredGovernorates[index];

                final isSelected =
                    governorate ==
                        widget.selectedGovernorate;

                return ListTile(
                  leading: const Icon(
                    Icons.account_balance,
                    color: Color(0xFF6EA6C1),
                  ),

                  title: Text(
                    governorate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),

                  trailing: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? const Color(0xFF6EA6C1)
                        : Colors.white54,
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                      governorate,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}
