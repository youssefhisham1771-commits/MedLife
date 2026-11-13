import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _db = FirebaseFirestore.instance;
const _blue = Color(0xFF1769E0);
String _money(dynamic value) {
  final n = double.tryParse(value?.toString() ?? '') ?? 0;
  return 'EGP ${NumberFormat('#,##0.00').format(n)}';
}
String _date(dynamic value) {
  if (value is Timestamp) return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
  return '—';
}
void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class AdminModulePage extends StatelessWidget {
  const AdminModulePage({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1: return const OrdersAdminPage();
      case 2: return const ProductsAdminPage();
      case 3: return const InventoryAdminPage();
      case 4: return const CustomersAdminPage();
      case 5: return const CategoriesAdminPage();
      case 6: return const BannersAdminPage();
      case 7: return const AnalyticsAdminPage();
      case 8: return const ReportsAdminPage();
      case 9: return const StaffAdminPage();
      case 10: return const NotificationsAdminPage();
      case 11: return const AssistantAdminPage();
      case 12: return const SettingsAdminPage();
      case 13: return const ActivityAdminPage();
      case 14: return const BackupAdminPage();
      default: return const Center(child: Text('Select a module'));
    }
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.title, required this.subtitle, required this.child, this.action});
  final String title, subtitle;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 16), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ])),
      if (action != null) action!,
    ])),
    Expanded(child: child),
  ]);
}

class OrdersAdminPage extends StatefulWidget {
  const OrdersAdminPage({super.key});
  @override
  State<OrdersAdminPage> createState() => _OrdersAdminPageState();
}
class _OrdersAdminPageState extends State<OrdersAdminPage> {
  String status = 'All';
  String search = '';
  final controller = TextEditingController();
  static const statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Orders',
    subtitle: 'Review customer orders and update their fulfillment status.',
    child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
        TextField(controller: controller, onChanged: (v) => setState(() => search = v.trim().toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search order ID, customer or phone')),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', ...statuses].map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.toUpperCase()),
                selected: status == s,
                onSelected: (_) => setState(() => status = s),
              ),
            )).toList(),
          ),
        ),
      ])),
      const SizedBox(height: 12),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('orders').orderBy('orderedAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load orders. Check your Firestore access.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) {
            final x = d.data();
            final matchesStatus = status == 'All' || (x['status'] ?? '').toString().toLowerCase() == status;
            final q = search;
            return matchesStatus && (q.isEmpty || d.id.toLowerCase().contains(q) || (x['name'] ?? '').toString().toLowerCase().contains(q) || (x['phone'] ?? '').toString().toLowerCase().contains(q));
          }).toList();
          if (docs.isEmpty) return const Center(child: Text('No matching orders.'));
          return ListView.separated(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data(); final items = (d['items'] as List?) ?? [];
            return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text((d['orderNumber'] ?? '#${doc.id}').toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                _StatusPill(status: (d['status'] ?? 'pending').toString()),
                PopupMenuButton<String>(tooltip: 'Update status', onSelected: (v) async { try { await doc.reference.update({'status': v}); if (context.mounted) _message(context, 'Order status updated.'); } catch (e) { if (context.mounted) _message(context, 'Update failed: $e'); } }, itemBuilder: (_) => statuses.map((s) => PopupMenuItem(value: s, child: Text('Set ${s.toUpperCase()}'))).toList()),
              ]),
              const SizedBox(height: 6),
              Text('${d['name'] ?? 'Unknown customer'} • ${d['phone'] ?? 'No phone'}'),
              Text('${items.length} item(s) • ${_money(d['total'])} • ${_date(d['orderedAt'])}', style: Theme.of(context).textTheme.bodySmall),
              if ((d['address'] ?? '').toString().isNotEmpty) Text('Delivery: ${d['governorate'] ?? ''} ${d['address']}', maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              ExpansionTile(title: const Text('Order items and payment breakdown'), tilePadding: EdgeInsets.zero, children: [
                ...items.map((item) => ListTile(dense: true, title: Text((item['name'] ?? 'Product').toString()), subtitle: Text('Size: ${item['size'] ?? '—'} • Qty: ${item['quantity'] ?? 1}'), trailing: Text(_money(item['price'])))),
                ListTile(title: const Text('Shipping'), trailing: Text(_money(d['shipping']))),
                ListTile(title: const Text('Discount'), trailing: Text(_money(d['discount']))),
                ListTile(title: const Text('Total'), trailing: Text(_money(d['total']), style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ])));
          });
        },
      )),
    ]),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) { 'delivered' => Colors.green, 'cancelled' => Colors.red, 'processing' => Colors.deepPurple, 'shipped' => Colors.blue, _ => Colors.orange };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }
}

class ProductsAdminPage extends StatefulWidget {
  const ProductsAdminPage({super.key});
  @override
  State<ProductsAdminPage> createState() => _ProductsAdminPageState();
}
class _ProductsAdminPageState extends State<ProductsAdminPage> {
  String search = '';
  Future<void> editProduct([QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final result = await showDialog<bool>(context: context, builder: (_) => _ProductEditor(initial: doc?.data(), documentId: doc?.id));
    if (result == true && mounted) _message(context, doc == null ? 'Product added.' : 'Product updated.');
  }
  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Products',
    subtitle: 'Manage the products displayed in the existing MedLife store.',
    action: FilledButton.icon(onPressed: () => editProduct(), icon: const Icon(Icons.add), label: const Text('Add Product')),
    child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(onChanged: (v) => setState(() => search = v.toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products by name or category'))),
      const SizedBox(height: 12),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('Products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load Products collection.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) => d.data().toString().toLowerCase().contains(search)).toList();
          if (docs.isEmpty) return const Center(child: Text('No products found.'));
          return ListView.separated(padding: const EdgeInsets.all(24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data(); final images = (d['images'] as List?) ?? []; final image = images.isNotEmpty ? images.first.toString() : (d['image'] ?? '').toString();
            return Card(child: ListTile(
              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: image.startsWith('http') ? Image.network(image, width: 52, height: 58, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 52, child: Icon(Icons.image_not_supported))) : const SizedBox(width: 52, child: Icon(Icons.inventory_2))),
              title: Text((d['name'] ?? 'Unnamed product').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_money(d['price'])} • ${d['category'] ?? 'Uncategorized'}'),
              trailing: PopupMenuButton<String>(onSelected: (v) async {
                if (v == 'edit') { await editProduct(doc); }
                if (v == 'delete') {
                  final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete product?'), content: Text('Delete ${d['name'] ?? 'this product'} from the store?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))]));
                  if (yes == true) { try { await doc.reference.delete(); if (context.mounted) _message(context, 'Product deleted.'); } catch (e) { if (context.mounted) _message(context, 'Delete failed: $e'); } }
                }
              }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
            ));
          });
        },
      )),
    ]),
  );
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({this.initial, this.documentId});
  final Map<String, dynamic>? initial;
  final String? documentId;
  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}
class _ProductEditorState extends State<_ProductEditor> {
  late final name = TextEditingController(text: widget.initial?['name']?.toString() ?? '');
  late final price = TextEditingController(text: widget.initial?['price']?.toString() ?? '');
  late final description = TextEditingController(text: widget.initial?['description']?.toString() ?? '');
  late final delivery = TextEditingController(text: widget.initial?['deliveryText']?.toString() ?? '');
  late final image = TextEditingController(text: ((widget.initial?['images'] as List?)?.join(', ') ?? widget.initial?['image']?.toString()) ?? '');
  late final category = TextEditingController(text: widget.initial?['category']?.toString() ?? '');
  bool saving = false;
  Future<void> save() async {
    final parsedPrice = double.tryParse(price.text.trim());
    if (name.text.trim().isEmpty || parsedPrice == null || parsedPrice < 0) { _message(context, 'Enter a product name and a valid non-negative price.'); return; }
    setState(() => saving = true);
    try {
      final images = image.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final data = <String, dynamic>{
        'name': name.text.trim(), 'price': price.text.trim(),
        'description': description.text.trim(), 'deliveryText': delivery.text.trim(),
        'category': category.text.trim(), 'images': images,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.initial == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('Products').add(data);
      } else {
        await _db.collection('Products').doc(widget.documentId).update(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message(context, 'Could not save product: $e');
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  void dispose() { name.dispose(); price.dispose(); description.dispose(); delivery.dispose(); image.dispose(); category.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add Product' : 'Edit Product'),
    content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name')),
      const SizedBox(height: 10),
      TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price (EGP)')),
      const SizedBox(height: 10),
      TextField(controller: category, decoration: const InputDecoration(labelText: 'Category name')),
      const SizedBox(height: 10),
      TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      const SizedBox(height: 10),
      TextField(controller: delivery, decoration: const InputDecoration(labelText: 'Delivery text')),
      const SizedBox(height: 10),
      TextField(controller: image, maxLines: 2, decoration: const InputDecoration(labelText: 'Image URL(s)', helperText: 'Separate multiple image URLs with commas.')),
    ]))),
    actions: [TextButton(onPressed: saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Saving…' : 'Save Product'))],
  );
}

class CategoriesAdminPage extends StatelessWidget {
  const CategoriesAdminPage({super.key});
  Future<void> _edit(BuildContext context, [QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final c = TextEditingController(text: doc?.data()['name']?.toString() ?? '');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: Text(doc == null ? 'Add Category' : 'Edit Category'), content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Category name')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isNotEmpty), child: const Text('Save'))]));
    if (ok == true) {
      try {
        if (doc == null) { await _db.collection('categories').add({'name': c.text.trim(), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}); }
        else { await doc.reference.update({'name': c.text.trim(), 'updatedAt': FieldValue.serverTimestamp()}); }
        if (context.mounted) _message(context, 'Category saved.');
      } catch (e) { if (context.mounted) _message(context, 'Could not save category: $e'); }
    }
    c.dispose();
  }
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Categories', subtitle: 'Manage the categories shared with the MedLife storefront.', action: FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add), label: const Text('Add Category')), child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('categories').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load categories.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    if (snap.data!.docs.isEmpty) return const Center(child: Text('No categories yet.'));
    return ListView(padding: const EdgeInsets.all(24), children: snap.data!.docs.map((doc) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.category_outlined)), title: Text((doc.data()['name'] ?? 'Unnamed').toString()), subtitle: Text('ID: ${doc.id}'), trailing: Wrap(children: [
      IconButton(onPressed: () => _edit(context, doc), icon: const Icon(Icons.edit_outlined)),
      IconButton(onPressed: () async { final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete category?'), content: const Text('Products already assigned to this category will not be deleted, but may retain the old category name.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])); if (yes == true) { try { await doc.reference.delete(); if (context.mounted) _message(context, 'Category deleted.'); } catch (e) { if (context.mounted) _message(context, 'Delete failed: $e'); } } }, icon: const Icon(Icons.delete_outline, color: Colors.red)),
    ])))).toList());
  }));
}

class CustomersAdminPage extends StatefulWidget {
  const CustomersAdminPage({super.key});
  @override
  State<CustomersAdminPage> createState() => _CustomersAdminPageState();
}
class _CustomersAdminPageState extends State<CustomersAdminPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Customers', subtitle: 'Customer profiles from the existing users collection.', child: Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, email or phone'))),
    const SizedBox(height: 12),
    Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('users').snapshots(), builder: (context, snap) {
      if (snap.hasError) return const Center(child: Text('Could not load users. The current security rules may restrict listing.'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snap.data!.docs.where((d) { final x = d.data(); return (x['role'] ?? 'user') != 'admin' && (query.isEmpty || x.toString().toLowerCase().contains(query)); }).toList();
      if (docs.isEmpty) return const Center(child: Text('No customers found.'));
      return ListView.separated(padding: const EdgeInsets.all(24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) { final d = docs[i].data(); return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text((d['name'] ?? d['fullName'] ?? 'Customer').toString()), subtitle: Text('${d['email'] ?? 'No email'} • ${d['phone'] ?? 'No phone'}'), trailing: const Icon(Icons.chevron_right), onTap: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text((d['name'] ?? 'Customer').toString()), content: SelectableText('Email: ${d['email'] ?? '—'}\nPhone: ${d['phone'] ?? '—'}\nUser ID: ${docs[i].id}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))])))); });
    })),
  ]));
}

class InventoryAdminPage extends StatelessWidget {
  const InventoryAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Inventory', subtitle: 'Stock visibility based on fields currently available in the product records.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('Products').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load products.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final docs = snap.data!.docs;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.info_outline, color: _blue), const SizedBox(width: 12), const Expanded(child: Text('The current MedLife product schema does not contain a stock quantity per size. This page is read-only until an inventory data model and matching security rules are approved; it will not invent or overwrite stock values.'))]))),
      const SizedBox(height: 12),
      ...docs.map((d) { final x = d.data(); final sizes = (x['sizes'] as List?)?.join(', ') ?? 'Sizes not stored'; return Card(child: ListTile(leading: const Icon(Icons.inventory_2_outlined), title: Text((x['name'] ?? 'Product').toString()), subtitle: Text('Sizes: $sizes'), trailing: Text(_money(x['price'])))); }),
    ]);
  }));
}

class BannersAdminPage extends StatelessWidget {
  const BannersAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Marketing • Banners', subtitle: 'Review existing promotional banners. Campaign publishing will be added after its data contract is verified.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('banners').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load banners.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    if (snap.data!.docs.isEmpty) return const Center(child: Text('No banners found.'));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: snap.data!.docs.map((d) => Card(
        child: ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text((d.data()['title'] ?? d.data()['name'] ?? 'Banner').toString()),
          subtitle: Text(d.id),
        ),
      )).toList(),
    );
  }));
}

class AnalyticsAdminPage extends StatelessWidget {
  const AnalyticsAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Analytics', subtitle: 'Live order-based business indicators.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('orders').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load analytics.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final docs = snap.data!.docs;
    final revenue = docs.where((d) => (d.data()['status'] ?? '') != 'cancelled').fold<double>(0, (sum, d) => sum + (double.tryParse(d.data()['total']?.toString() ?? '') ?? 0));
    final delivered = docs.where((d) => d.data()['status'] == 'delivered').length;
    final pending = docs.where((d) => d.data()['status'] == 'pending').length;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _Kpi(title: 'All Orders', value: docs.length.toString(), icon: Icons.shopping_bag_outlined),
        _Kpi(title: 'Gross Order Value*', value: _money(revenue), icon: Icons.payments_outlined),
        _Kpi(title: 'Delivered', value: delivered.toString(), icon: Icons.check_circle_outline),
        _Kpi(title: 'Pending', value: pending.toString(), icon: Icons.pending_actions),
      ]),
      const SizedBox(height: 14),
      const Text('*Sum of non-cancelled order totals; this is not accounting net revenue and may include shipping.'),
    ]);
  }));
}

class ReportsAdminPage extends StatelessWidget {
  const ReportsAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Reports', subtitle: 'Operational report preview from live Firestore records.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('orders').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load report data.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    final docs = snap.data!.docs;
    final rows = docs.map((d) => '${d.id},${(d.data()['name'] ?? '').toString().replaceAll(',', ' ')},${d.data()['status'] ?? ''},${d.data()['total'] ?? 0},${_date(d.data()['orderedAt'])}').toList();
    final csv = ['Order ID,Customer,Status,Total EGP,Ordered At', ...rows].join('\\n');
    return ListView(padding: const EdgeInsets.all(24), children: [
      _Kpi(title: 'Orders in report', value: docs.length.toString(), icon: Icons.description_outlined),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(csv.isEmpty ? 'No data' : csv))),
      const SizedBox(height: 8),
      const Text('CSV preview is available here. Download/export integration will be added in the next reporting milestone.'),
    ]);
  }));
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.title, required this.value, required this.icon});
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(width: 220, child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(icon, color: _blue, size: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodySmall), Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]))]))));
}

class StaffAdminPage extends StatelessWidget {
  const StaffAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Staff & Permissions', subtitle: 'Current admin accounts. Role editing is intentionally disabled until the custom permission model and rules are implemented.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('users').where('role', isEqualTo: 'admin').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load admin accounts.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    if (snap.data!.docs.isEmpty) return const Center(child: Text('No admin profiles found.'));
    return ListView(padding: const EdgeInsets.all(24), children: snap.data!.docs.map((d) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)), title: Text((d.data()['name'] ?? 'Administrator').toString()), subtitle: Text('${d.data()['email'] ?? d.id} • role: admin')))).toList());
  }));
}

class NotificationsAdminPage extends StatelessWidget {
  const NotificationsAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'Notifications', subtitle: 'Notification records currently stored in Firestore.', child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: _db.collection('notifications').snapshots(), builder: (context, snap) {
    if (snap.hasError) return const Center(child: Text('Could not load notifications.'));
    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
    if (snap.data!.docs.isEmpty) return const Center(child: Text('No notification records found.'));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: snap.data!.docs.map((d) => Card(
        child: ListTile(
          leading: const Icon(Icons.notifications_none),
          title: Text((d.data()['title'] ?? 'Notification').toString()),
          subtitle: Text((d.data()['body'] ?? d.data()['message'] ?? '').toString()),
          trailing: Text(_date(d.data()['createdAt'])),
        ),
      )).toList(),
    );
  }));
}

class AssistantAdminPage extends StatelessWidget {
  const AssistantAdminPage({super.key});
  @override
  Widget build(BuildContext context) => _PageFrame(title: 'MedLife AI Assistant', subtitle: 'Data-grounded insights with secure, read-only access are planned for this workspace.', child: ListView(padding: const EdgeInsets.all(24), children: const [
    Card(child: Padding(padding: EdgeInsets.all(20), child: Row(children: [Icon(Icons.auto_awesome, color: _blue, size: 34), SizedBox(width: 14), Expanded(child: Text('The assistant must query authorized MedLife data through a secure backend. No external AI key is embedded in this app.'))]))),
    SizedBox(height: 12),
    Card(child: ListTile(title: Text('Suggested questions'), subtitle: Text('Which products are top sellers?\\nHow many orders are pending?\\nSummarize sales for the last 30 days.'))),
  ]));
}

class SettingsAdminPage extends StatelessWidget {
  const SettingsAdminPage({super.key});
  @override
  Widget build(BuildContext context) => const _PageFrame(title: 'System Settings', subtitle: 'Configuration changes will be enabled after settings ownership and storefront contracts are confirmed.', child: Center(child: Text('No system settings are modified in this milestone.')));
}
class ActivityAdminPage extends StatelessWidget {
  const ActivityAdminPage({super.key});
  @override
  Widget build(BuildContext context) => const _PageFrame(title: 'Activity Log', subtitle: 'Audit trail will be connected after a trusted server-side writer is implemented.', child: Center(child: Text('No audit events have been generated by this admin app yet.')));
}
class BackupAdminPage extends StatelessWidget {
  const BackupAdminPage({super.key});
  @override
  Widget build(BuildContext context) => const _PageFrame(title: 'Backup & Restore', subtitle: 'Backup and restore require a trusted server-side export and recovery workflow.', child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Backup and restore are not enabled in the client app. This protects production data from unsafe or partial restores.'))));
}
