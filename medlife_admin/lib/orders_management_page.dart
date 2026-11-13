import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OrdersManagementPage extends StatefulWidget {
  const OrdersManagementPage({super.key});

  @override
  State<OrdersManagementPage> createState() => _OrdersManagementPageState();
}

class _OrdersManagementPageState extends State<OrdersManagementPage> {
  static const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  final searchController = TextEditingController();
  String search = '';
  String selectedStatus = 'all';

  CollectionReference<Map<String, dynamic>> get orders =>
      FirebaseFirestore.instance.collection('orders');

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  double number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  String money(dynamic value) =>
      'EGP ' + NumberFormat('#,##0.00').format(number(value));

  String date(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy • hh:mm a').format(value.toDate());
    }
    return 'Date unavailable';
  }

  List<Map<String, dynamic>> itemsOf(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item)).toList();
  }

  void notifyUser(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> copyText(String value, String label) async {
    if (value.trim().isEmpty) {
      notifyUser('No ' + label + ' available.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    notifyUser(label + ' copied.');
  }

  Future<void> changeStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> order,
    String next,
  ) async {
    final current = (order.data()['status'] ?? 'pending').toString().toLowerCase();
    if (current == next) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update order status?'),
        content: Text(
          'Change ' + (order.data()['orderNumber'] ?? order.id).toString() +
          ' from ' + current.toUpperCase() + ' to ' + next.toUpperCase() + '?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final updates = <String, dynamic>{'status': next};
      // deliveredAt is an existing field in the current order schema.
      if (next == 'delivered') {
        updates['deliveredAt'] = FieldValue.serverTimestamp();
      }
      await order.reference.update(updates);
      notifyUser('Order status updated.');
    } catch (error) {
      notifyUser('Could not update order: ' + error.toString());
    }
  }

  void showDetails(QueryDocumentSnapshot<Map<String, dynamic>> order) {
    final data = order.data();
    final items = itemsOf(data['items']);
    final subtotal = items.fold<double>(0, (sum, item) {
      final quantity = number(item['quantity']) == 0 ? 1 : number(item['quantity']);
      return sum + number(item['price']) * quantity;
    });
    final address = [
      data['addressTitle'],
      data['governorate'],
      data['address'],
    ].where((part) => part != null && part.toString().trim().isNotEmpty).join(' • ');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text((data['orderNumber'] ?? order.id).toString()),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detailLine('Customer', (data['name'] ?? 'Unknown').toString()),
                detailLine('Phone', (data['phone'] ?? 'Not provided').toString(),
                  trailing: IconButton(
                    tooltip: 'Copy phone',
                    onPressed: () => copyText((data['phone'] ?? '').toString(), 'Phone'),
                    icon: const Icon(Icons.copy_outlined),
                  )),
                detailLine('Order date', date(data['orderedAt'])),
                detailLine('Status', (data['status'] ?? 'pending').toString().toUpperCase()),
                detailLine('Address', address.isEmpty ? 'Not provided' : address),
                const Divider(height: 28),
                Text('Items (' + items.length.toString() + ')',
                  style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (items.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No item details were saved with this order.')),
                ...items.map((item) {
                  final quantity = number(item['quantity']) == 0 ? 1 : number(item['quantity']);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text((item['name'] ?? 'Product').toString()),
                    subtitle: Text('Size: ' + (item['size'] ?? '—').toString() +
                      ' • Qty: ' + quantity.toStringAsFixed(0)),
                    trailing: Text(money(number(item['price']) * quantity)),
                  );
                }),
                const Divider(height: 28),
                detailLine('Subtotal (items)', money(subtotal)),
                detailLine('Shipping', money(data['shipping'])),
                detailLine('Discount', money(data['discount'])),
                detailLine('Total', money(data['total']), emphasized: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () => copyText(order.id, 'Order ID'),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy order ID'),
          ),
        ],
      ),
    );
  }

  Widget detailLine(String label, String value,
      {Widget? trailing, bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 125, child: Text(label,
            style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value,
            style: emphasized ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (value) => setState(() => search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search order number, customer, phone or ID',
                  suffixIcon: search.isEmpty ? null : IconButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() => search = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['all', ...statuses].map((value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value.toUpperCase()),
                      selected: selectedStatus == value,
                      onSelected: (_) => setState(() => selectedStatus = value),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: orders.orderBy('orderedAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Unable to load orders. Check Firestore access and the orderedAt field.',
                    textAlign: TextAlign.center),
                ));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final all = snapshot.data!.docs;
              final counts = <String, int>{
                for (final status in statuses)
                  status: all.where((doc) =>
                    (doc.data()['status'] ?? 'pending').toString().toLowerCase() == status).length,
              };
              final filtered = all.where((doc) {
                final data = doc.data();
                final status = (data['status'] ?? 'pending').toString().toLowerCase();
                final text = [
                  doc.id, data['orderNumber'], data['name'], data['phone']
                ].whereType<Object>().join(' ').toLowerCase();
                return (selectedStatus == 'all' || status == selectedStatus) &&
                  (search.isEmpty || text.contains(search));
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        countChip('All', all.length),
                        for (final status in statuses)
                          countChip(status, counts[status] ?? 0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                      ? Center(child: Text(all.isEmpty
                          ? 'No orders have been received yet.'
                          : 'No orders match your search or filter.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            final data = order.data();
                            final orderItems = itemsOf(data['items']);
                            final status = (data['status'] ?? 'pending').toString().toLowerCase();
                            final number = (data['orderNumber'] ?? '#' + order.id).toString();
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(number,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                                        statusPill(status),
                                        PopupMenuButton<String>(
                                          tooltip: 'Change status',
                                          onSelected: (value) => changeStatus(order, value),
                                          itemBuilder: (_) => statuses.map((value) =>
                                            PopupMenuItem<String>(
                                              value: value,
                                              enabled: value != status,
                                              child: Text('Set ' + value.toUpperCase()),
                                            )).toList(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text((data['name'] ?? 'Unknown customer').toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 3),
                                    Text((data['phone'] ?? 'No phone').toString(),
                                      style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 14,
                                      runSpacing: 6,
                                      children: [
                                        meta(Icons.shopping_bag_outlined, orderItems.length.toString() + ' item(s)'),
                                        meta(Icons.calendar_today_outlined, date(data['orderedAt'])),
                                        meta(Icons.payments_outlined, money(data['total'])),
                                      ],
                                    ),
                                    if ((data['governorate'] ?? '').toString().isNotEmpty ||
                                        (data['address'] ?? '').toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      meta(Icons.location_on_outlined,
                                        [data['governorate'], data['address']]
                                          .where((part) => part != null && part.toString().trim().isNotEmpty)
                                          .join(' • ')),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => showDetails(order),
                                        icon: const Icon(Icons.receipt_long_outlined),
                                        label: const Text('View full details'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget countChip(String label, int count) => Chip(
    label: Text(label.toUpperCase() + '  ' + count.toString()),
    visualDensity: VisualDensity.compact,
  );

  Widget meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: Colors.grey),
      const SizedBox(width: 5),
      Text(text, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget statusPill(String status) {
    final color = switch (status) {
      'delivered' => Colors.green,
      'cancelled' => Colors.red,
      'processing' => Colors.deepPurple,
      'shipped' => Colors.blue,
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
