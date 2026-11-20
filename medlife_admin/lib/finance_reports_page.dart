import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:fl_chart/fl_chart.dart';
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
  bool exporting = false;

  static const statuses = ['All', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'];

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

  bool inRange(DateTime? date, DateTimeRange range) {
    if (date == null) return false;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day + 1);
    return !date.isBefore(start) && date.isBefore(end);
  }

  Future<void> exportCsv(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final rows = <List<dynamic>>[
        ['Order ID', 'Order Number', 'Customer', 'Status', 'Subtotal EGP', 'Shipping EGP', 'Discount EGP', 'Total EGP', 'Ordered At'],
        ...docs.map((doc) {
          final data = doc.data();
          final shipping = amount(data['shipping']);
          final discount = amount(data['discount']);
          final total = amount(data['total']);
          return [
            doc.id,
            data['orderNumber'] ?? '',
            data['name'] ?? '',
            data['status'] ?? 'pending',
            (total - shipping + discount).toStringAsFixed(2),
            shipping.toStringAsFixed(2),
            discount.toStringAsFixed(2),
            total.toStringAsFixed(2),
            dateLabel(orderDate(data['orderedAt'])),
          ];
        }),
      ];
      final csv = rows.map((row) => row.map(csvCell).join(',')).join('\r\n');
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await FileSaver.instance.saveFile(
        name: 'medlife_finance_report_$stamp',
        bytes: Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]),
        fileExtension: 'csv',
        mimeType: MimeType.custom,
        customMimeType: 'text/csv',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV report export completed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export report: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load financial report data. Check Firestore access.'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data();
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          if (selectedStatus != 'All' && status != selectedStatus) return false;
          if (selectedRange != null && !inRange(orderDate(data['orderedAt']), selectedRange!)) return false;
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
          if (status == 'cancelled') {
            cancelledCount++;
            continue;
          }
          activeOrderValue += total;
          shippingTotal += amount(data['shipping']);
          discountTotal += amount(data['discount']);
          if (status == 'delivered') {
            deliveredCount++;
            deliveredOrderValue += total;
          }
          if (status == 'pending') pendingCount++;
        }

        final now = DateTime.now();
        final currentRange = selectedRange ??
            DateTimeRange(start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)), end: DateTime(now.year, now.month, now.day));
        final periodDays = currentRange.end.difference(currentRange.start).inDays + 1;
        final previousRange = DateTimeRange(
          start: currentRange.start.subtract(Duration(days: periodDays)),
          end: currentRange.start.subtract(const Duration(days: 1)),
        );
        double rangeValue(DateTimeRange range) => allDocs.fold<double>(0, (sum, doc) {
          final data = doc.data();
          if ((data['status'] ?? 'pending').toString().toLowerCase() == 'cancelled' ||
              !inRange(orderDate(data['orderedAt']), range)) return sum;
          return sum + amount(data['total']);
        });
        final previousValue = rangeValue(previousRange);
        final currentValue = rangeValue(currentRange);
        final difference = currentValue - previousValue;
        final changePercent = previousValue == 0 ? null : difference / previousValue * 100;

        final chartStart = DateTime(now.year, now.month - 5, 1);
        final monthlyValues = <DateTime, double>{};
        for (var i = 0; i < 6; i++) {
          final month = DateTime(chartStart.year, chartStart.month + i, 1);
          monthlyValues[month] = 0;
        }
        for (final doc in allDocs) {
          final data = doc.data();
          if ((data['status'] ?? 'pending').toString().toLowerCase() == 'cancelled') continue;
          final date = orderDate(data['orderedAt']);
          if (date == null) continue;
          final key = DateTime(date.year, date.month, 1);
          if (monthlyValues.containsKey(key)) monthlyValues[key] = monthlyValues[key]! + amount(data['total']);
        }
        final maxMonthly = monthlyValues.values.fold<double>(0, (a, b) => a > b ? a : b);

        final productTotals = <String, _ProductSummary>{};
        for (final doc in filteredDocs) {
          final data = doc.data();
          if ((data['status'] ?? 'pending').toString().toLowerCase() == 'cancelled') continue;
          final items = data['items'];
          if (items is! List) continue;
          for (final item in items) {
            if (item is! Map) continue;
            final name = (item['name'] ?? 'Unnamed product').toString();
            final quantity = amount(item['quantity'] ?? 1);
            final revenue = amount(item['price']) * quantity;
            final old = productTotals[name] ?? _ProductSummary();
            productTotals[name] = _ProductSummary(
              quantity: old.quantity + quantity,
              value: old.value + revenue,
            );
          }
        }
        final topProducts = productTotals.entries.toList()
          ..sort((a, b) => b.value.value.compareTo(a.value.value));

        final csvRows = <String>[
          ['Order ID', 'Order Number', 'Customer', 'Status', 'Subtotal EGP', 'Shipping EGP', 'Discount EGP', 'Total EGP', 'Ordered At'].map(csvCell).join(','),
          ...filteredDocs.map((doc) {
            final data = doc.data();
            final shipping = amount(data['shipping']);
            final discount = amount(data['discount']);
            final total = amount(data['total']);
            return [
              doc.id, data['orderNumber'] ?? '', data['name'] ?? '', data['status'] ?? 'pending',
              (total - shipping + discount).toStringAsFixed(2), shipping.toStringAsFixed(2),
              discount.toStringAsFixed(2), total.toStringAsFixed(2), dateLabel(orderDate(data['orderedAt'])),
            ].map(csvCell).join(',');
          }),
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Finance & Reports', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Order-value and fulfillment summaries based on live order records.'),
                ])),
                OutlinedButton.icon(
                  onPressed: chooseRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(selectedRange == null ? 'Last 30 days' : '${DateFormat('dd MMM').format(selectedRange!.start)} – ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}'),
                ),
                if (selectedRange != null) IconButton(tooltip: 'Clear date filter', onPressed: () => setState(() => selectedRange = null), icon: const Icon(Icons.close)),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: exporting ? null : () => exportCsv(filteredDocs),
                  icon: exporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                  label: Text(exporting ? 'Exporting' : 'Export CSV'),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(alignment: Alignment.centerLeft, child: Wrap(
                spacing: 8, runSpacing: 8,
                children: statuses.map((status) => ChoiceChip(
                  label: Text(status.toUpperCase()),
                  selected: selectedStatus == status,
                  onSelected: (_) => setState(() => selectedStatus = status),
                )).toList(),
              )),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    _FinanceMetric(title: 'Orders in period', value: filteredDocs.length.toString(), icon: Icons.receipt_long_outlined),
                    _FinanceMetric(title: 'Active order value', value: money(activeOrderValue), icon: Icons.payments_outlined),
                    _FinanceMetric(title: 'Delivered order value', value: money(deliveredOrderValue), icon: Icons.task_alt_outlined),
                    _FinanceMetric(title: 'Delivered orders', value: deliveredCount.toString(), icon: Icons.local_shipping_outlined),
                    _FinanceMetric(title: 'Pending orders', value: pendingCount.toString(), icon: Icons.pending_actions_outlined),
                    _FinanceMetric(title: 'Cancelled orders', value: cancelledCount.toString(), icon: Icons.cancel_outlined),
                    _FinanceMetric(title: 'Shipping in active orders', value: money(shippingTotal), icon: Icons.delivery_dining_outlined),
                    _FinanceMetric(title: 'Discounts in active orders', value: money(discountTotal), icon: Icons.discount_outlined),
                  ]),
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    title: 'Period comparison',
                    subtitle: 'Non-cancelled order value compared with the previous period of equal length.',
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Current: ${money(currentValue)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Previous: ${money(previousValue)}'),
                      const SizedBox(height: 8),
                      Text(changePercent == null
                          ? (currentValue == 0 ? 'No order value in either period.' : 'No previous-period value to calculate a percentage change.')
                          : '${difference >= 0 ? 'Increase' : 'Decrease'} of ${money(difference.abs())} (${changePercent.abs().toStringAsFixed(1)}%).',
                        style: TextStyle(fontWeight: FontWeight.w700, color: changePercent == null ? null : difference >= 0 ? Colors.green : Colors.red),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: 'Monthly order value',
                    subtitle: 'Last six calendar months, excluding cancelled orders.',
                    child: SizedBox(
                      height: 230,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxMonthly <= 0 ? 10 : maxMonthly * 1.2,
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 58, getTitlesWidget: (value, meta) => Text(NumberFormat.compact().format(value), style: Theme.of(context).textTheme.bodySmall))),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= monthlyValues.length) return const SizedBox.shrink();
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MMM').format(monthlyValues.keys.elementAt(index)), style: Theme.of(context).textTheme.bodySmall));
                          })),
                        ),
                        barGroups: monthlyValues.entries.toList().asMap().entries.map((entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [BarChartRodData(toY: entry.value.value, width: 22, borderRadius: BorderRadius.circular(5))],
                        )).toList(),
                      )),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: 'Top products',
                    subtitle: 'Ranked by item value (unit price × quantity) in the selected date and status filters, excluding cancelled orders.',
                    child: topProducts.isEmpty
                        ? const Text('No product items found for these filters.')
                        : Column(children: topProducts.take(10).toList().asMap().entries.map((entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(child: Text('${entry.key + 1}')),
                            title: Text(entry.value.key),
                            subtitle: Text('Quantity: ${NumberFormat('#,##0.##').format(entry.value.value.quantity)}'),
                            trailing: Text(money(entry.value.value.value), style: const TextStyle(fontWeight: FontWeight.w700)),
                          )).toList()),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: 'How to read these figures',
                    subtitle: 'Calculation notes',
                    child: const Text('Active order value is the sum of saved order totals for orders that are not cancelled. It includes shipping and is not confirmed cash collected. Delivered order value is not proof of payment settlement. Subtotal is derived as total − shipping + discount. Product ranking uses item price × quantity and may not reconcile exactly with order totals when order-level discounts or adjustments apply.'),
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
                      return Card(child: ExpansionTile(
                        title: Text((data['orderNumber'] ?? '#${doc.id}').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${data['name'] ?? 'Customer'} • ${status.toUpperCase()} • ${dateLabel(orderDate(data['orderedAt']))}'),
                        trailing: Text(money(amount(data['total']))),
                        children: [
                          ListTile(title: const Text('Subtotal'), trailing: Text(money(amount(data['total']) - amount(data['shipping']) + amount(data['discount'])))),
                          ListTile(title: const Text('Shipping'), trailing: Text(money(amount(data['shipping'])))),
                          ListTile(title: const Text('Discount'), trailing: Text(money(amount(data['discount'])))),
                          ListTile(title: const Text('Order total'), trailing: Text(money(amount(data['total'])))),
                          if (items.isNotEmpty) ...items.whereType<Map>().map((item) => ListTile(
                            dense: true,
                            title: Text((item['name'] ?? 'Product').toString()),
                            subtitle: Text('Qty: ${item['quantity'] ?? 1} • Size: ${item['size'] ?? '—'}'),
                            trailing: Text(money(amount(item['price']) * amount(item['quantity'] ?? 1))),
                          )),
                        ],
                      ));
                    }),
                  const SizedBox(height: 14),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('CSV export preview'),
                    subtitle: const Text('Preview of the same filtered rows included in the downloaded report.'),
                    children: [Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(csvRows.map((row) => row).join('\n')))],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required String subtitle, required Widget child}) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 14),
      child,
    ])));
  }
}

class _ProductSummary {
  const _ProductSummary({this.quantity = 0, this.value = 0});
  final double quantity;
  final double value;
}

class _FinanceMetric extends StatelessWidget {
  const _FinanceMetric({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 235,
    child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 27),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ])),
    ]))),
  );
}
