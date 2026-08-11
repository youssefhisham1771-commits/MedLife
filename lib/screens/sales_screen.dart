import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


import 'product_details_screen.dart';
import 'edit_sale_screen.dart';
import 'add_sale_screen.dart';


class SalesScreen extends StatelessWidget {
  final bool isAdmin;

  const SalesScreen({
  super.key,
  required this.isAdmin,
});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF07070A)
              : const Color(0xFFF5F5F7),

      appBar: AppBar(
        backgroundColor:
            isDark
                ? const Color(0xFF07070A)
                : const Color(0xFFF5F5F7),

        elevation: 0,

        title: Text(
          "Sales",

          style: TextStyle(
            color:
                isDark
                    ? Colors.white
                    : Colors.black,

            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),

        iconTheme: IconThemeData(
          color:
              isDark
                  ? Colors.white
                  : Colors.black,
        ),

        actions: [
          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.search,
              size: 28,
            ),
          ),

          IconButton(
            onPressed: () {},

            icon: const Icon(
              Icons.tune,
              size: 28,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      floatingActionButton:
          isAdmin
              ? Container(
                width: 64,
                height: 64,

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF7CC7FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: 0.35),

                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),

                child: FloatingActionButton(
                  backgroundColor:
                      Colors.transparent,

                  elevation: 0,

                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder:
                            (_) => AddSaleScreen(),
                      ),
                    );
                  },

                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )
              : null,

      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('sales')
                .orderBy(
                  'createdAt',
                  descending: true,
                )
                .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          var sales = snapshot.data!.docs;

if (!isAdmin) {
  sales = sales.where((doc) {

    final sale = doc.data();

    if (sale['expiryDate'] == null) {
      return true;
    }

    final expiryDate =
        (sale['expiryDate'] as Timestamp)
            .toDate();

    return expiryDate.isAfter(
      DateTime.now(),
    );

  }).toList();
}

          if (sales.isEmpty) {
            return Center(
              child: Text(
                "No Sales Yet",

                style: TextStyle(
                  color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                ),
              ),
            );
          }

          int totalSales = sales.length;

          double avgDiscount =
              sales.fold<double>(
                0.0,
                (total, item) =>
                    total +
                    ((item.data()['discount'] ??
                                    0)
                                as num)
                            .toDouble(),
              ) /
              sales.length;

              double totalDiscountValue =
    sales.fold<double>(
      0.0,
      (total, item) {
        var sale = item.data();

        double price =
            ((sale['price'] ?? 0) as num).toDouble();

        double discount =
            ((sale['discount'] ?? 0) as num).toDouble();

        return total + (price * discount / 100);
      },
    );

    int activeSales =
    sales.where((saleDoc) {

  final data =
      saleDoc.data();

  final expiry =
      (data['expiryDate']
              as Timestamp)
          .toDate();

  return expiry.isAfter(
      DateTime.now());

}).length;

          return ListView(
            padding:
                const EdgeInsets.all(18),

            children: [
              /// STATS
              Container(
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 22,
                    ),

                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(22),

                  gradient:
                      isDark
                          ? const LinearGradient(
                            colors: [
                              Color(0xFF15111A),
                              Color(0xFF100C14),
                            ],
                            begin:
                                Alignment.topLeft,
                            end: Alignment
                                .bottomRight,
                          )
                          : null,

                  color:
                      isDark
                          ? null
                          : Colors.white,

                  border: Border.all(
                    color: Colors.white
                        .withValues(alpha: 0.05),
                  ),
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [
                    statItem(
                      Icons.local_offer_outlined,
                      "Total Sales",
                      "$totalSales",
                    ),

                    divider(),

                    statItem(
                      Icons
                          .shopping_bag_outlined,
                      "Active Sales",
                      "$activeSales",
                    ),

                    divider(),

                    statItem(
                      Icons.percent,
                      "Avg. Discount",
                      "${avgDiscount.toInt()}%",
                    ),

                    divider(),

                    statItem(
  Icons.attach_money,
  "Total Discount",
  "${totalDiscountValue.toStringAsFixed(0)} EGP",
),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// SALES LIST
              ...List.generate(
                sales.length,
                (index) {
                  var sale =
                      sales[index].data();

                          DateTime expiryDate =
    (sale['expiryDate'] as Timestamp).toDate();

bool isExpired =
    expiryDate.isBefore(DateTime.now());

                  return Container(
                    height: 170,

                    margin:
                        const EdgeInsets.only(
                          bottom: 18,
                        ),

                    padding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                            30,
                          ),

                      gradient:
                          isDark
                              ? const LinearGradient(
                                colors: [
                                  Color(
                                    0xFF15121A,
                                  ),
                                  Color(
                                    0xFF0E0C12,
                                  ),
                                ],
                                begin:
                                    Alignment
                                        .topLeft,
                                end: Alignment
                                    .bottomRight,
                              )
                              : null,

                      color:
                          isDark
                              ? null
                              : Colors.white,

                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 
                              0.05,
                            ),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 
                                0.28,
                              ),

                          blurRadius: 18,

                          offset:
                              const Offset(
                                0,
                                8,
                              ),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .center,

                      children: [
                        /// IMAGE
                        Container(
                          width: 102,
                          height: 102,

                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                                  28,
                                ),

                            gradient:
                                LinearGradient(
                                  colors: [
                                    Colors.white
                                        .withValues(alpha: 
                                          0.06,
                                        ),

                                    Colors.white
                                        .withValues(alpha: 
                                          0.02,
                                        ),
                                  ],

                                  begin:
                                      Alignment
                                          .topLeft,

                                  end: Alignment
                                      .bottomRight,
                                ),
                          ),

                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                                  24,
                                ),

                            child:
                                sale['image'] !=
                                            null &&
                                        sale['image']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.network(
                                      sale['image'],

                                      fit:
                                          BoxFit
                                              .cover,
                                    )
                                    : const Icon(
                                      Icons.image,
                                      color:
                                          Colors
                                              .white54,

                                      size: 38,
                                    ),
                          ),
                        ),

                        const SizedBox(
                          width: 16,
                        ),

                        /// INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                            children: [
                              /// TITLE
                              Text(
                                sale['title'] ??
                                    "",

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors
                                              .white
                                          : Colors
                                              .black,

                                  fontSize: 18,

                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              /// DETAILS
                              Text(
                                sale['details'] ??
                                    "",

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style: TextStyle(
                                  color:
                                      isDark
                                          ? Colors
                                              .white70
                                          : Colors
                                              .black54,

                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              /// DISCOUNT
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal:
                                          16,
                                      vertical:
                                          10,
                                    ),

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            18,
                                          ),

                                      border:
                                          Border.all(
                                            color: const Color(
                                              0xFF2F5BFF,
                                            ).withValues(alpha: 
                                              0.25,
                                            ),
                                          ),

                                      color: Colors
                                          .black
                                          .withValues(alpha: 
                                            0.18,
                                          ),
                                    ),

                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,

                                  children: [
                                    const Icon(
                                      Icons
                                          .local_offer_outlined,

                                      color: Color(
                                        0xFF4A8DFF,
                                      ),

                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Text(
                                      "${sale['discount']}% OFF",

                                      style:
                                          const TextStyle(
                                            color:
                                                Color(
                                                  0xFF4A8DFF,
                                                ),

                                            fontSize:
                                                16,

                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              /// DATE + STATUS
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .calendar_today_outlined,

                                    color:
                                        Colors
                                            .white70,

                                    size: 15,
                                  ),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
  sale['expiryDate'] != null
      ? DateFormat(
          'dd MMM yyyy',
        ).format(
          (sale['expiryDate'] as Timestamp)
              .toDate(),
        )
      : "No Expiry Date",
  style: TextStyle(
    color: isDark
        ? Colors.white70
        : Colors.black54,
    fontSize: 12,
  ),
),

                                  const SizedBox(
                                    width: 16,
                                  ),

                                  Container(
  width: 7,
  height: 7,
  decoration: BoxDecoration(
    color: isExpired
        ? Colors.red
        : const Color(0xFF6DFF4D),
    shape: BoxShape.circle,
  ),
),

                                  const SizedBox(
                                    width: 5,
                                  ),

                                  Text(
  isExpired ? "Expired" : "Active",
  style: TextStyle(
    color: isExpired
        ? Colors.red
        : const Color(0xFF6DFF4D),
    fontSize: 13,
    fontWeight: FontWeight.w600,
  ),
),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        /// BUTTONS
                        Column(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [
                            buildActionButton(
                              icon: Icons
                                  .arrow_forward_ios,

                              color: const Color(
                                0xFF4A8DFF,
                              ),

                              onTap:
                                  () async {
                                var product =
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                          'Products',
                                        )
                                        .doc(
                                          sale['productId'],
                                        )
                                        .get();

                                        if (!context.mounted) return;

                                if (product
                                    .exists) {
                                  Navigator.push(
                                    context,


                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              ProductDetailsScreen(
                                                product:
                                                    product,

                                                cart:
                                                    [],

                                                onAddToCart:
                                                    () {},
                                              ),
                                    ),
                                  );
                                }
                              },
                            ),

                            if (isAdmin) ...[
                              const SizedBox(
                                height: 10,
                              ),

                              buildActionButton(
                                icon: Icons
                                    .edit_outlined,

                                color:
                                    const Color(
                                      0xFF4A8DFF,
                                    ),

                                onTap: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              EditSaleScreen(
                                                saleId:
                                                    sales[index]
                                                        .id,

                                                saleData:
                                                    sale,
                                              ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              buildActionButton(
                                icon: Icons
                                    .delete_outline,

                                color:
                                    Colors
                                        .redAccent,

                                onTap:
                                    () async {
                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                        'sales',
                                      )
                                      .doc(
                                        sales[index]
                                            .id,
                                      )
                                      .delete();

                                      if (!context.mounted) return;

                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Sale Deleted",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildActionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,

    child: Container(
      width: 40,
      height: 40,

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        color: const Color(0xFF1F1B27),

        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),

      child: Icon(
        icon,
        color: color,
        size: 17,
      ),
    ),
  );
}

  Widget divider() {
    return Container(
      width: 1,
      height: 70,

      color: Colors.white.withValues(alpha: 
        0.08,
      ),
    );
  }

  Widget statItem(
    IconData icon,
    String title,
    String value,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(
          icon,
          color: const Color(0xFF3B82F6),
          size: 34,
        ),

        const SizedBox(height: 3),

        Text(
          title,

          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,

          style: const TextStyle(
            color: Color(0xFF3B82F6),

            fontSize: 16,

            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}