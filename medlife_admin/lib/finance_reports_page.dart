import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceReportsPage extends StatefulWidget {
  const FinanceReportsPage({super.key});

  @override
  State<FinanceReportsPage> createState() => _FinanceReportsPageState();
}

class _FinanceReportsPageState extends State<FinanceReportsPage> {
  DateTimeRange? selectedRange;
  String selectedStatus = 'All';

  static const statuses = [
    'All',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  double amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? orderDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String money(double value) => 'EGP ${NumberFormat('#,##0.00').format(value)}';

  String dateLabel(DateTime? value) =>
      value == null ? 'Date unavailable' : DateFormat('dd MMM yyyy, hh:mm a').format(value);

  String csvCell(dynamic value) {
    final text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  Future<void> chooseRange() async {
    final now = DateTime.now();
    final initial = selectedRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)),
          end: DateTime(now.year, now.month, now.day),
        );
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initial,
    );
    if (result != null && mounted) setState(() => selectedRange = result);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load financial report data. Check Firestore access.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data();
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          if (selectedStatus != 'All' && status != selectedStatus) return false;
          if (selectedRange != null) {
            final date = orderDate(data['orderedAt']);
            if (date == null) return false;
            final start = DateTime(
              selectedRange!.start.year,
              selectedRange!.start.month,
              selectedRange!.start.day,
            );
            final endExclusive = DateTime(
              selectedRange!.end.year,
              selectedRange!.end.month,
              selectedRange!.end.day + 1,
            );
            if (date.isBefore(start) || !date.isBefore(endExclusive)) return false;
          }
          return true;
        }).toList()
          ..sort((a, b) {
            final aDate = orderDate(a.data()['orderedAt']);
            final bDate = orderDate(b.data()['orderedAt']);
            return (bDate ?? DateTime(1970)).compareTo(aDate ?? DateTime(1970));
          });

        var activeOrderValue = 0.0;
        var deliveredOrderValue = 0.0;
        var shippingTotal = 0.0;
        var discountTotal = 0.0;
        var cancelledCount = 0;
        var deliveredCount = 0;
        var pendingCount = 0;

        for (final doc in filteredDocs) {
          final data = doc.data();
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final total = amount(data['total']);
          final shipping = amount(data['shipping']);
          final discount = amount(data['discount']);

          if (status == 'cancelled') {
            cancelledCount++;
            continue;
          }

          activeOrderValue += total;
          shippingTotal += shipping;
          discountTotal += discount;
          if (status == 'delivered') {
            deliveredCount++;
            deliveredOrderValue += total;
          }
          if (status == 'pending') pendingCount++;
        }

        final csvRows = <String>[
          ['Order ID', 'Order Number', 'Customer', 'Status', 'Subtotal EGP', 'Shipping EGP', 'Discount EGP', 'Total EGP', 'Ordered At']
              .map(csvCell).join(','),
          ...filteredDocs.map((doc) {
            final data = doc.data();
            final shipping = amount(data['shipping']);
            final discount = amount(data['discount']);
            final total = amount(data['total']);
            final subtotal = total - shipping + discount;
            return [
              doc.id,
              data['orderNumber'] ?? '',
              data['name'] ?? '',
              data['status'] ?? 'pending',
              subtotal.toStringAsFixed(2),
              shipping.toStringAsFixed(2),
              discount.toStringAsFixed(2),
              total.toStringAsFixed(2),
              dateLabel(orderDate(data['orderedAt'])),
            ].map(csvCell).join(',');
          }),
        ];
        final csvPreview = csvRows.join('\n');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Finance & Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Order-value and fulfillment summaries based on live order records.'),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: chooseRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(selectedRange == null
                        ? 'All dates'
                        : '${DateFormat('dd MMM').format(selectedRange!.start)} – ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}'),
                  ),
                  if (selectedRange != null)
                    IconButton(
                      tooltip: 'Clear date filter',
                      onPressed: () => setState(() => selectedRange = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuses.map((status) => ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: selectedStatus == status,
                    onSelected: (_) => setState(() => selectedStatus = status),
                  )).toList(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _FinanceMetric(title: 'Orders in period', value: filteredDocs.length.toString(), icon: Icons.receipt_long_outlined),
                      _FinanceMetric(title: 'Active order value', value: money(activeOrderValue), icon: Icons.payments_outlined),
                      _FinanceMetric(title: 'Delivered order value', value: money(deliveredOrderValue), icon: Icons.task_alt_outlined),
                      _FinanceMetric(title: 'Delivered orders', value: deliveredCount.toString(), icon: Icons.local_shipping_outlined),
                      _FinanceMetric(title: 'Pending orders', value: pendingCount.toString(), icon: Icons.pending_actions_outlined),
                      _FinanceMetric(title: 'Cancelled orders', value: cancelledCount.toString(), icon: Icons.cancel_outlined),
                      _FinanceMetric(title: 'Shipping in active orders', value: money(shippingTotal), icon: Icons.delivery_dining_outlined),
                      _FinanceMetric(title: 'Discounts in active orders', value: money(discountTotal), icon: Icons.discount_outlined),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How to read these figures', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Active order value is the sum of total for orders that are not cancelled. It includes shipping and reflects the saved order total, not confirmed cash collected. Delivered order value is also an order-value indicator, not proof of payment settlement.'),
                          const SizedBox(height: 6),
                          Text('Subtotal is derived as total − shipping + discount. Cancelled orders are excluded from active value, shipping and discount totals.', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (filteredDocs.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No orders match the selected filters.')))
                  else
                    ...filteredDocs.map((doc) {
                      final data = doc.data();
                      final status = (data['status'] ?? 'pending').toString();
                      final items = data['items'] is List ? data['items'] as List : const [];
                      return Card(
                        child: ExpansionTile(
                          title: Text((data['orderNumber'] ?? '#${doc.id}').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${data['name'] ?? 'Customer'} • ${status.toUpperCase()} • ${dateLabel(orderDate(data['orderedAt']))}'),
                          trailing: Text(money(amount(data['total']))),
                          children: [
                            ListTile(title: const Text('Subtotal'), trailing: Text(money(amount(data['total']) - amount(data['shipping']) + amount(data['discount'])))),
                            ListTile(title: const Text('Shipping'), trailing: Text(money(amount(data['shipping'])))),
                            ListTile(title: const Text('Discount'), trailing: Text(money(amount(data['discount'])))),
                            ListTile(title: const Text('Order total'), trailing: Text(money(amount(data['total'])))),
                            if (items.isNotEmpty)
                              ...items.map((item) => ListTile(
                                dense: true,
                                title: Text((item is Map ? item['name'] : 'Product')?.toString() ?? 'Product'),
                                subtitle: Text('Qty: ${item is Map ? item['quantity'] ?? 1 : 1} • Size: ${item is Map ? item['size'] ?? '—' : '—'}'),
                                trailing: Text(money(item is Map ? amount(item['price']) * amount(item['quantity'] ?? 1) : 0)),
                              )),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 14),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('CSV export preview'),
                    subtitle: const Text('Copyable data preview; file download is not enabled in this milestone.'),
                    children: [
                      Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(csvPreview))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 27),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
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
}
