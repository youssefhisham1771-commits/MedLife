import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/offline_storage_service.dart';
import 'my_order_details_screen.dart';

class OrdersList extends StatelessWidget {
  final String status;
  const OrdersList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view orders'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: OfflineStorageService().loadPendingOrders(user.uid),
      builder: (context, localSnapshot) {
        final localEntries = localSnapshot.data ?? <Map<String, dynamic>>[];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .where('status', isEqualTo: status)
              .orderBy('orderedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final remoteOrders = snapshot.data!.docs;
            final remoteIds = remoteOrders.map((doc) => doc.id).toSet();
            final pendingLocal = status == 'pending'
                ? localEntries.where((entry) {
                    final id = entry['localId']?.toString();
                    final payload = entry['payload'];
                    return id != null && !remoteIds.contains(id) && payload is Map;
                  }).toList()
                : <Map<String, dynamic>>[];

            if (remoteOrders.isEmpty && pendingLocal.isEmpty) {
              return const Center(child: Text('No Orders'));
            }

            return ListView(
              children: [
                ...pendingLocal.map((entry) {
                  final data = Map<String, dynamic>.from(entry['payload'] as Map);
                  final items = (data['items'] as List?) ?? [];
                  final date = DateTime.tryParse(data['orderedAt']?.toString() ?? '');
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(data['orderNumber']?.toString() ?? 'Offline order'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.map((item) => Text(
                            '• ${item['name']} | Size: ${item['size'] ?? '-'} | Qty: ${item['quantity'] ?? 1}',
                          )),
                          const SizedBox(height: 8),
                          if (date != null) Text(DateFormat('dd MMM yyyy').format(date)),
                          Text('Total: ${data['total']} EGP',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('PENDING SYNC', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 5),
                          const Text('Saved on this device. Waiting for internet connection.',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }),
                ...remoteOrders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final order = entry.value;
                  final data = order.data();
                  final orderedAt = data['orderedAt'];
                  final deliveredAt = data['deliveredAt'];
                  final orderedDate = orderedAt is Timestamp
                      ? DateFormat('dd MMM yyyy').format(orderedAt.toDate())
                      : '';
                  final deliveredDate = deliveredAt is Timestamp
                      ? DateFormat('dd MMM yyyy').format(deliveredAt.toDate())
                      : '';
                  final items = (data['items'] as List?) ?? [];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text('Order #${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...items.map((item) => Text(
                            '• ${item['name']} | Size: ${item['size'] ?? '-'} | Qty: ${item['quantity'] ?? 1} × (${item['price']})',
                          )),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.calendar_month_outlined, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(orderedDate, style: const TextStyle(color: Colors.white70)),
                          ]),
                          if (status == 'delivered' && deliveredDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(children: [
                                const Icon(Icons.check_circle, color: Color(0xFF6EA6C1), size: 18),
                                const SizedBox(width: 8),
                                Text('Delivered: $deliveredDate',
                                  style: const TextStyle(color: Color(0xFF6EA6C1))),
                              ]),
                            ),
                          Text('Total: ${data['total']} EGP',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status == 'pending' ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MyOrderDetailsScreen(order: order),
                        ));
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
