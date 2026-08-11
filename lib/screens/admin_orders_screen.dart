import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'order_details_screen.dart';


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {

      String selectedFilter = 'Newest First';
      String selectedStatus = 'All';
      bool isSearching = false;

String searchQuery = '';

TextEditingController searchController =
    TextEditingController();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF07070A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF07070A),
        elevation: 0,

        title: isSearching

    ? TextField(

        controller: searchController,

        onChanged: (value) {

          setState(() {

            searchQuery = value;

          });
        },

        style: const TextStyle(
          color: Colors.white,
        ),

        decoration: const InputDecoration(

          hintText:
              'Search by ID, name or phone...',

          hintStyle: TextStyle(
            color: Colors.white54,
          ),

          border: InputBorder.none,
        ),
      )

    : const Text(

        "Admin Dashboard",

        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

        iconTheme:
            const IconThemeData(color: Colors.white),

        actions: [
          IconButton(

  onPressed: () {

    setState(() {

      if (isSearching) {

        isSearching = false;

        searchQuery = '';

        searchController.clear();

      } else {

        isSearching = true;
      }
    });
  },

  icon: Icon(

    isSearching
        ? Icons.close
        : Icons.search,

    size: 26,
  ),
),

          PopupMenuButton<String>(
  icon: const Icon(
    Icons.filter_list_rounded,
    size: 26,
    color: Colors.white,
  ),

  onSelected: (value) {
    setState(() {
      selectedFilter = value;
    });
  },

  itemBuilder: (context) => [

    const PopupMenuItem(
      value: 'Newest First',
      child: Text('Newest First'),
    ),

    const PopupMenuItem(
      value: 'Oldest First',
      child: Text('Oldest First'),
    ),

    const PopupMenuItem(
      value: 'Highest Price',
      child: Text('Highest Price'),
    ),

    const PopupMenuItem(
      value: 'Lowest Price',
      child: Text('Lowest Price'),
    ),
  ],
),

          const SizedBox(width: 6),
        ],
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
    .collection('orders')
    .orderBy(
      'orderedAt',
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

          var orders = snapshot.data!.docs;

          List sortedOrders = List.from(orders);

          if (selectedStatus != 'All') {

  sortedOrders = sortedOrders.where((order) {

    String status =
        (order['status'] ?? '')
            .toString()
            .toLowerCase();

    return status ==
        selectedStatus.toLowerCase();

  }).toList();
}

if (searchQuery.isNotEmpty) {

  sortedOrders =
      sortedOrders.where((order) {

    final data =
        order.data()
            as Map<String, dynamic>;

    String name =
        (data['name'] ?? '')
            .toString()
            .toLowerCase();

    String phone =
        (data['phone'] ?? '')
            .toString()
            .toLowerCase();

    String id =
    order.id
        .substring(0, 6)
        .toLowerCase();

    String query =
        searchQuery.toLowerCase();

    return name.contains(query) ||

        phone.contains(query) ||

        id.contains(query);

  }).toList();
}

if (selectedFilter == 'Oldest First') {

  sortedOrders = orders.reversed.toList();

} else if (selectedFilter ==
    'Highest Price') {

  sortedOrders.sort((a, b) {

    double aTotal =
        (a['total'] ?? 0).toDouble();

    double bTotal =
        (b['total'] ?? 0).toDouble();

    return bTotal.compareTo(aTotal);
  });

} else if (selectedFilter ==
    'Lowest Price') {

  sortedOrders.sort((a, b) {

    double aTotal =
        (a['total'] ?? 0).toDouble();

    double bTotal =
        (b['total'] ?? 0).toDouble();

    return aTotal.compareTo(bTotal);
  });
}


          if (orders.isEmpty) {

  return const Center(
    child: Text(
      "No Orders Yet",

      style: TextStyle(
        color: Colors.white,
      ),
    ),
  );
}

if (sortedOrders.isEmpty) {

  return const Center(
    child: Text(
      "No Orders Found!",

      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

          int totalOrders = orders.length;

          int deliveredCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'delivered',
              )
              .length;

          int pendingCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'pending',
              )
              .length;

          int processingCount = orders
              .where(
                (e) =>
                    (e['status'] ?? '') ==
                    'processing',
              )
              .length;

          return ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              /// STATS
              Row(
                children: [
                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.shopping_bag_outlined,

                      title: "Total Orders",

                      value:
                          totalOrders.toString(),

                      color:
                          const Color(
                            0xFF3B82F6,
                          ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.access_time,

                      title: "Pending",

                      value:
                          pendingCount.toString(),

                      color:
                          Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.local_shipping_outlined,

                      title: "Processing",

                      value:
                          processingCount
                              .toString(),

                      color:
                          Colors.purpleAccent,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: dashboardStat(
                      icon:
                          Icons.check_circle_outline,

                      title: "Delivered",

                      value:
                          deliveredCount
                              .toString(),

                      color:
                          Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "Recent Orders",

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

SingleChildScrollView(
  scrollDirection: Axis.horizontal,

  child: Row(
    children: [

      statusChip('All'),
      statusChip('Pending'),
      statusChip('Processing'),
      statusChip('Delivered'),

    ],
  ),
),

const SizedBox(height: 20),

              ...List.generate(
                sortedOrders.length,
                (i) {
                  var order = sortedOrders[i];

                  final data =
                      order.data()
                          as Map<
                            String,
                            dynamic
                          >;

                  List items =
    data['items'] ?? [];

int totalQuantity = 0;

for (var item in items) {

  totalQuantity +=
      ((item['quantity'] ?? 1) as num).toInt();
}

String status =
    data['status'] ??
        'pending';

                  Color statusColor =
                      status == 'delivered'
                          ? Colors.green
                          : status ==
                              'processing'
                          ? Colors.purpleAccent
                          : Colors.orange;

                  Timestamp? orderedAt =
                      data['orderedAt'];


                  return Container(
                    margin:
                        const EdgeInsets.only(
                          bottom: 18,
                        ),

                    padding:
                        const EdgeInsets.all(
                          16,
                        ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                            28,
                          ),

                      gradient:
                          const LinearGradient(
                            colors: [
                              Color(
                                0xFF15121A,
                              ),
                              Color(
                                0xFF0C0B10,
                              ),
                            ],

                            begin:
                                Alignment
                                    .topLeft,

                            end: Alignment
                                .bottomRight,
                          ),

                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 
                              0.05,
                            ),
                      ),
                    ),

                    child: Column(
                      children: [
                        /// TOP
Row(
  crossAxisAlignment: CrossAxisAlignment.start,

  children: [

    /// ORDER INFO
    SizedBox(
      width: 120,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            "ORDER NUM: ${(sortedOrders.length - i).toString().padLeft(4, '0')}",

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "ID: ${order.id.substring(0, 6)}",

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),

    const Spacer(),

    Padding(
  padding: const EdgeInsets.only(right: 15),

  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),

    decoration: BoxDecoration(
      borderRadius:
          BorderRadius.circular(12),

      color: statusColor.withValues(alpha: 
        0.18,
      ),
    ),

    child: Text(
      status.toUpperCase(),

      style: TextStyle(
        color: statusColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  ),
),

    const Spacer(),

    SizedBox(
  width: 100,

  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.center,

    children: [

      Text(
        DateFormat(
          'MMM dd, yyyy',
        ).format(
          orderedAt!.toDate(),
        ),

        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,

        style: const TextStyle(
          color: Colors.white54,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 2),

      Text(
        DateFormat(
          'hh:mm a',
        ).format(
          orderedAt.toDate(),
        ),

        textAlign: TextAlign.center,

        style: const TextStyle(
          color: Colors.white38,
          fontSize: 15,
        ),
      ),
    ],
  ),
),
  ],
),

                        const SizedBox(height: 18),

                        /// USER INFO
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            CircleAvatar(
                              radius: 28,

                              backgroundColor:
                                  Colors.white12,

                              child: Text(
                                data['name'] !=
                                            null &&
                                        data['name']
                                            .toString()
                                            .isNotEmpty
                                    ? data['name'][0]
                                    : "U",

                                style:
                                    const TextStyle(
                                      color:
                                          Colors
                                              .white,

                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize:
                                          22,
                                    ),
                              ),
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    data['name'] ??
                                        "No Name",

                                    style:
                                        const TextStyle(
                                          color:
                                              Colors
                                                  .white,

                                          fontSize:
                                              20,

                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    data['phone'] ??
                                        "",

                                    style:
                                        const TextStyle(
                                          color:
                                              Colors
                                                  .white60,

                                          fontSize:
                                              14,
                                        ),
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  SizedBox(
  height: 25,

  child: Row(
    children: [

      ...List.generate(

        items.length > 3 ? 3 : items.length,

        (index) {

          var item = items[index];

          return Container(
            width: 25,
            height: 25,

            margin: const EdgeInsets.only(
              right: 5,
            ),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                    10,
                  ),

              color: Colors.white10,
            ),

            child:
                item['image'] != null &&
                        item['image']
                            .toString()
                            .isNotEmpty
                    ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                            16,
                          ),

                      child:
                          Image.network(
                        item['image'],

                        fit:
                            BoxFit.cover,
                      ),
                    )
                    : const Icon(
                      Icons.image,
                      color:
                          Colors.white38,
                    ),
          );
        },
      ),

      if (items.length > 3)

        Container(
          width: 25,
          height: 25,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
                  16,
                ),

            color: Colors.white10,
          ),

          child: Center(
            child: Text(
              "+${items.length - 3}",

              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .end,

                              children: [
                                const Text(
                                  "Total Amount",

                                  style:
                                      TextStyle(
                                        color:
                                            Colors
                                                .white54,

                                        fontSize:
                                            14,
                                      ),
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Text(
                                  "${data['total'] ?? 0} EGP",

                                  style:
                                      const TextStyle(
                                        color:
                                            Colors
                                                .white,

                                        fontSize:
                                            26,

                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  "$totalQuantity Items",

                                  style:
                                      const TextStyle(
                                        color:
                                            Colors
                                                .white54,

                                        fontSize:
                                            13,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        /// BUTTONS
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,

                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              OrderDetailsScreen(
                                                order:
                                                    order,
                                              ),
                                    ),
                                  );
                                },

                                child: Container(
                                  height: 52,

                                  decoration:
                                      BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                              16,
                                            ),

                                        border: Border.all(
                                          color:
                                              const Color(
                                                0xFF3B82F6,
                                              ),
                                        ),
                                      ),

                                  child:
                                      const Center(
                                        child: Text(
                                          "View Details",

                                          style:
                                              TextStyle(
                                                color:
                                                    Color(
                                                      0xFF3B82F6,
                                                    ),

                                                fontWeight:
                                                    FontWeight.bold,

                                                fontSize:
                                                    15,
                                              ),
                                        ),
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            GestureDetector(
                              onTap: () async {

  String newStatus = 'pending';

  if (status == 'pending') {

    newStatus = 'processing';

  } else if (status == 'processing') {

    newStatus = 'delivered';

  } else {

    newStatus = 'pending';
  }

  await FirebaseFirestore.instance
      .collection('orders')
      .doc(order.id)
      .update({

    "status": newStatus,

    if (newStatus == 'delivered')
      "deliveredAt":
          FieldValue.serverTimestamp(),
  });
},
                              child: Container(
                                width: 56,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),

                                      gradient:
                                          const LinearGradient(
                                            colors: [
                                              Color(
                                                0xFF3B82F6,
                                              ),
                                              Color(
                                                0xFF6CB7FF,
                                              ),
                                            ],
                                          ),
                                    ),

                                child: const Icon(
                                  Icons
                                      .local_shipping_outlined,

                                  color:
                                      Colors
                                          .white,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            GestureDetector(
                              onTap: () async {
                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                      'orders',
                                    )
                                    .doc(order.id)
                                    .delete();
                              },

                              child: Container(
                                width: 56,
                                height: 52,

                                decoration:
                                    BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),

                                      color:
                                          Colors.red
                                              .withValues(alpha: 
                                                0.12,
                                              ),
                                    ),

                                child: const Icon(
                                  Icons
                                      .delete_outline,

                                  color:
                                      Colors.red,
                                ),
                              ),
                            ),
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

Widget statusChip(String title) {

  bool isSelected =
      selectedStatus == title;

  return GestureDetector(

    onTap: () {

      setState(() {

        selectedStatus = title;

      });
    },

    child: Container(

      margin: const EdgeInsets.only(
        right: 10,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(30),

        color: isSelected
            ? Colors.white
            : Colors.white.withValues(alpha: 
                0.05,
              ),

        border: Border.all(

          color: isSelected
              ? Colors.white
              : Colors.white12,
        ),
      ),

      child: Text(

        title,

        style: TextStyle(

          color: isSelected
              ? Colors.black
              : Colors.white70,

          fontWeight:
              FontWeight.w600,

          fontSize: 14,
        ),
      ),
    ),
  );
}

  Widget dashboardStat({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 140,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        gradient: const LinearGradient(
          colors: [
            Color(0xFF15121A),
            Color(0xFF0D0B10),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        border: Border.all(
          color: Colors.white.withValues(alpha: 
            0.05,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(14),

              color: color.withValues(alpha: 0.12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const Spacer(),

          Text(
            title,

            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,

            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}