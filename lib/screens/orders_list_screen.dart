import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'my_order_details_screen.dart';


class OrdersList extends StatelessWidget {
  final String status;

  const OrdersList({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
stream: FirebaseFirestore.instance
.collection('orders')
.where("userId", isEqualTo: user!.uid)
.where("status", isEqualTo: status)
.orderBy("orderedAt", descending: true)
.snapshots(),
builder: (context, snapshot) {

if (snapshot.hasError) {
  return Center(child: Text("Error: ${snapshot.error}"));
}

if (!snapshot.hasData) {
return Center(child: CircularProgressIndicator()); }

        var orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(child: Text("No Orders"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, i) {
            var order = orders[i];
            var data = order.data();

Timestamp? orderedAt = data['orderedAt'];
Timestamp? deliveredAt = data['deliveredAt'];

String orderedDate = orderedAt != null
    ? DateFormat('dd MMM yyyy').format(
        orderedAt.toDate(),
      )
    : '';

String deliveredDate = deliveredAt != null
    ? DateFormat('dd MMM yyyy').format(
        deliveredAt.toDate(),
      )
    : '';

            List items = data['items'] ?? [];

            return Card(
              margin: EdgeInsets.all(10),
              child: ListTile(
                title: Text("Order #${i + 1}"),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 المنتجات
                    ...items.map<Widget>((item) {
                      return Text(
  "• ${item['name']} | Size: ${item['size'] ?? '-'} | Qty: ${item['quantity'] ?? 1} × (${item['price']})",
                      );
                    }),

                    SizedBox(height: 8),

                    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    /// 🔥 ORDER DATE
    Row(
      children: [

        Icon(
          Icons.calendar_month_outlined,
          color: Colors.white70,
          size: 18,
        ),

        SizedBox(width: 8),

        Text(
          orderedDate,

          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),

    /// 🔥 DELIVERED DATE
    if (data['status'] == "delivered" &&
        deliveredDate.isNotEmpty)

      Padding(
        padding: const EdgeInsets.only(top: 8),

        child: Row(
          children: [

            Icon(
              Icons.check_circle,
              color: Color(0xFF6EA6C1),
              size: 18,
            ),

            SizedBox(width: 8),

            Text(
              "Delivered: $deliveredDate",

              style: TextStyle(
                color: Color(0xFF6EA6C1),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
  ],
),

                    // 💰 التوتال
                    Text(
                      "Total: ${data['total']} EGP",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    SizedBox(height: 5),

                    // 🔄 الحالة
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: status == "pending"
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                trailing: Icon(Icons.arrow_forward),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MyOrderDetailsScreen(order: order),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}