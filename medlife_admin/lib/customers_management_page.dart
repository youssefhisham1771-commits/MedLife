import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomersManagementPage extends StatefulWidget {
  const CustomersManagementPage({super.key});

  @override
  State<CustomersManagementPage> createState() => _CustomersManagementPageState();
}

class _CustomersManagementPageState extends State<CustomersManagementPage> {
  final searchController = TextEditingController();
  String search = '';

  double amount(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String money(dynamic value) =>
      'EGP ' + NumberFormat('#,##0.00').format(amount(value));

  String date(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy • hh:mm a').format(value.toDate());
    }
    return 'Date unavailable';
  }

  List<Map<String, dynamic>> orderItems(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: TextField(
            controller: searchController,
            onChanged: (value) =>
                setState(() => search = value.trim().toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search customers by name, email, phone or ID',
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() => search = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return const Center(
                  child: Text('Could not load customers. Check admin access to the users collection.'),
                );
              }
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                builder: (context, ordersSnapshot) {
                  if (ordersSnapshot.hasError) {
                    return const Center(
                      child: Text('Customers loaded, but order history could not be loaded.'),
                    );
                  }
                  if (!ordersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = usersSnapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    final role = (data['role'] ?? 'user').toString().toLowerCase();
                    if (role == 'admin') return false;
                    final searchable = [
                      doc.id,
                      data['name'],
                      data['fullName'],
                      data['email'],
                      data['phone'],
                    ].whereType<Object>().join(' ').toLowerCase();
                    return search.isEmpty || searchable.contains(search);
                  }).toList();

                  final ordersByCustomer = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
                  for (final order in ordersSnapshot.data!.docs) {
                    final userId = order.data()['userId']?.toString();
                    if (userId == null || userId.isEmpty) continue;
                    ordersByCustomer.putIfAbsent(userId, () => []).add(order);
                  }

                  var totalCustomers = 0;
                  var customersWithOrders = 0;
                  var totalOrderValue = 0.0;
                  for (final doc in usersSnapshot.data!.docs) {
                    final data = doc.data();
                    if ((data['role'] ?? 'user').toString().toLowerCase() == 'admin') continue;
                    totalCustomers++;
                    final customerOrders = ordersByCustomer[doc.id] ?? [];
                    if (customerOrders.isNotEmpty) customersWithOrders++;
                    for (final order in customerOrders) {
                      final orderData = order.data();
                      if ((orderData['status'] ?? '').toString().toLowerCase() != 'cancelled') {
                        totalOrderValue += amount(orderData['total']);
                      }
                    }
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            metric('Customers', totalCustomers.toString(), Icons.people_outline),
                            metric('Purchased', customersWithOrders.toString(), Icons.shopping_bag_outlined),
                            metric('Order value • excl. cancelled', money(totalOrderValue), Icons.payments_outlined),
                          ],
                        ),
                      ),
                      Expanded(
                        child: customers.isEmpty
                            ? Center(
                                child: Text(totalCustomers == 0
                                    ? 'No customer profiles found.'
                                    : 'No customers match your search.'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                itemCount: customers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final customer = customers[index];
                                  final data = customer.data();
                                  final customerOrders = [...(ordersByCustomer[customer.id] ?? [])]
                                    ..sort((a, b) {
                                      final aDate = a.data()['orderedAt'];
                                      final bDate = b.data()['orderedAt'];
                                      final aMillis = aDate is Timestamp ? aDate.millisecondsSinceEpoch : 0;
                                      final bMillis = bDate is Timestamp ? bDate.millisecondsSinceEpoch : 0;
                                      return bMillis.compareTo(aMillis);
                                    });
                                  final spend = customerOrders.fold<double>(0, (sum, order) {
                                    final orderData = order.data();
                                    if ((orderData['status'] ?? '').toString().toLowerCase() == 'cancelled') return sum;
                                    return sum + amount(orderData['total']);
                                  });
                                  final name = (data['name'] ?? data['fullName'] ?? 'Customer').toString();
                                  final email = (data['email'] ?? 'No email').toString();
                                  final phone = (data['phone'] ?? 'No phone').toString();

                                  return Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        child: Text(name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase()),
                                      ),
                                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(email),
                                            Text(phone),
                                            const SizedBox(height: 5),
                                            Text(
                                              customerOrders.length.toString() + ' order(s)  •  ' + money(spend),
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => showCustomerDetails(
                                        customerId: customer.id,
                                        name: name,
                                        email: email,
                                        phone: phone,
                                        customerOrders: customerOrders,
                                        spend: spend,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget metric(String label, String value, IconData icon) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 27, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showCustomerDetails({
    required String customerId,
    required String name,
    required String email,
    required String phone,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> customerOrders,
    required double spend,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(name),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                infoLine('Email', email),
                infoLine('Phone', phone),
                infoLine('Customer ID', customerId),
                const Divider(height: 28),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    Text('Orders: ' + customerOrders.length.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Order value: ' + money(spend),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Purchase history',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (customerOrders.isEmpty)
                  const Text('This customer has no orders yet.')
                else
                  ...customerOrders.map((order) {
                    final data = order.data();
                    final items = orderItems(data['items']);
                    final orderNumber = (data['orderNumber'] ?? '#' + order.id).toString();
                    final status = (data['status'] ?? 'pending').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(orderNumber,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(status.toUpperCase() + ' • ' + date(data['orderedAt'])),
                        trailing: Text(money(data['total'])),
                        children: [
                          if (items.isEmpty)
                            const ListTile(title: Text('No saved item details.')),
                          ...items.map((item) => ListTile(
                            dense: true,
                            title: Text((item['name'] ?? 'Product').toString()),
                            subtitle: Text(
                              'Size: ' + (item['size'] ?? '—').toString() +
                              ' • Qty: ' + (item['quantity'] ?? 1).toString(),
                            ),
                            trailing: Text(money(item['price'])),
                          )),
                          ListTile(
                            dense: true,
                            title: const Text('Shipping'),
                            trailing: Text(money(data['shipping'])),
                          ),
                          ListTile(
                            dense: true,
                            title: const Text('Discount'),
                            trailing: Text(money(data['discount'])),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 105, child: Text(label,
            style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
