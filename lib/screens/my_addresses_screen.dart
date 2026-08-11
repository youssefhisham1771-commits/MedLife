import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  /// 🔥 LOAD ADDRESSES INSTANTLY
  Future<void> _loadAddresses() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
        "title": doc['title'],
        "address": doc['address'],
      });
    }

    setState(() {
      isLoading = false;
    });
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

              TextField(

                controller: addressController,

                maxLines: 3,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: InputDecoration(

                  labelText: "Address",

                  labelStyle: const TextStyle(
                    color: Colors.white70,
                  ),

                  hintText:
                      "Enter full address details",

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

                    if (titleController.text
                            .trim()
                            .isEmpty ||
                        addressController.text
                            .trim()
                            .isEmpty) {
                      return;
                    }

                    final user =
                        FirebaseAuth.instance
                            .currentUser;

                    if (user == null) return;

                    final newAddress = {
                      "title":
                          titleController.text
                              .trim(),

                      "address":
                          addressController.text
                              .trim(),
                    };

                    /// 🔥 INSTANT UI UPDATE
                    setState(() {

                      addresses.add({
                        "id": "",
                        ...newAddress,
                      });
                    });

                    Navigator.pop(context);

                    /// 🔥 SAVE TO FIREBASE
                    final doc =
                        await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(user.uid)
                            .collection(
                              'addresses',
                            )
                            .add(newAddress);

                    /// 🔥 UPDATE ID
                    final index =
                        addresses.indexWhere(
                      (e) => e["id"] == "",
                    );

                    if (index != -1) {

                      setState(() {

                        addresses[index]["id"] =
                            doc.id;
                      });
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

                    /// TOP CARD
                    Container(

                      width: double.infinity,

                      padding:
                          const EdgeInsets.all(
                            20,
                          ),

                      decoration: BoxDecoration(

                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),

                        gradient:
                            const LinearGradient(

                              colors: [
                                Color(0xFF1D1B20),
                                Color(0xFF141118),
                              ],
                            ),
                      ),

                      child: Row(
                        children: [

                          Container(

                            width: 70,
                            height: 70,

                            decoration: BoxDecoration(
                              color:
                                  blue.withValues(alpha: 
                                    .15,
                                  ),

                              shape:
                                  BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.location_on,
                              color: blue,
                              size: 36,
                            ),
                          ),

                          const SizedBox(
                            width: 18,
                          ),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                const Text(

                                  "Manage your addresses",

                                  style: TextStyle(
                                    color:
                                        mainText,

                                    fontSize:
                                        22,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                const Text(

                                  "You can add up to 3 addresses",

                                  style: TextStyle(
                                    color:
                                        subText,

                                    fontSize:
                                        15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(

                            padding:
                                const EdgeInsets.symmetric(
                                  horizontal:
                                      16,

                                  vertical:
                                      12,
                                ),

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

                            child: Text(

                              "${addresses.length}/3",

                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,

                                fontWeight:
                                    FontWeight
                                        .bold,

                                fontSize:
                                    20,
                              ),
                            ),
                          ),
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

                                        item['address'],

                                        style:
                                            const TextStyle(
                                          color:
                                              subText,

                                          fontSize:
                                              16,

                                          height:
                                              1.5,
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