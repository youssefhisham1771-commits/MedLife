import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'orders_management_page.dart';
import 'customers_management_page.dart';

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
      case 1: return const OrdersManagementPage();
      case 2: return const ProductsAdminPage();
      case 3: return const InventoryAdminPage();
      case 4: return const CustomersManagementPage();
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
  late final name = TextEditingController(
    text: widget.initial?['name']?.toString() ?? '',
  );
  late final price = TextEditingController(
    text: widget.initial?['price']?.toString() ?? '',
  );
  late final description = TextEditingController(
    text: widget.initial?['description']?.toString() ?? '',
  );
  late final delivery = TextEditingController(
    text: widget.initial?['deliveryText']?.toString() ?? '',
  );
  late final image = TextEditingController(
    text: widget.initial?['images'] is List
        ? (widget.initial!['images'] as List).join(', ')
        : widget.initial?['image']?.toString() ?? '',
  );
  late final category = TextEditingController(
    text: widget.initial?['category']?.toString() ?? '',
  );
  late final sizes = TextEditingController(
    text: widget.initial?['sizes'] is List
        ? (widget.initial!['sizes'] as List).join(', ')
        : '',
  );

  String? selectedCategoryId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.initial?['categoryId']?.toString();
  }

  Future<void> save() async {
    final parsedPrice = double.tryParse(price.text.trim());
    if (name.text.trim().isEmpty ||
        parsedPrice == null ||
        !parsedPrice.isFinite ||
        parsedPrice < 0) {
      _message(context, 'Enter a product name and a valid non-negative price.');
      return;
    }

    if (category.text.trim().isEmpty) {
      _message(context, 'Choose or enter a product category.');
      return;
    }

    setState(() => saving = true);
    try {
      final images = image.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      final productSizes = sizes.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

      String? categoryId = selectedCategoryId;
      if (categoryId != null) {
        final categoryDoc =
            await _db.collection('categories').doc(categoryId).get();
        if (!categoryDoc.exists) {
          throw StateError('The selected category no longer exists.');
        }
        category.text = categoryDoc.data()?['name']?.toString() ??
            category.text.trim();
      } else {
        final matchingCategories = await _db
            .collection('categories')
            .where('name', isEqualTo: category.text.trim())
            .limit(1)
            .get();
        if (matchingCategories.docs.isNotEmpty) {
          categoryId = matchingCategories.docs.first.id;
        }
      }

      if (widget.initial == null && categoryId == null) {
        throw StateError(
          'Select an existing category before adding a new product.',
        );
      }

      final data = <String, dynamic>{
        'name': name.text.trim(),
        // ProductModel reads price as a number, not a string.
        'price': parsedPrice,
        'description': description.text.trim(),
        'deliveryText': delivery.text.trim(),
        'category': category.text.trim(),
        'images': images,
        // Keep the legacy singular image field used by ProductModel.
        'image': images.isEmpty ? '' : images.first,
        'sizes': productSizes,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (categoryId != null) {
        data['categoryId'] = categoryId;
      }

      if (widget.initial == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('Products').add(data);
      } else {
        await _db.collection('Products').doc(widget.documentId).update(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _message(context, 'Could not save product: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    description.dispose();
    delivery.dispose();
    image.dispose();
    category.dispose();
    sizes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null ? 'Add Product' : 'Edit Product'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Product name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price (EGP)'),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final hasSelected =
                        docs.any((doc) => doc.id == selectedCategoryId);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: hasSelected ? selectedCategoryId : null,
                          decoration: const InputDecoration(
                            labelText: 'Choose existing category',
                          ),
                          items: docs
                              .map(
                                (doc) => DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    (doc.data()['name'] ?? 'Unnamed').toString(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  final selected =
                                      docs.firstWhere((doc) => doc.id == value);
                                  setState(() {
                                    selectedCategoryId = value;
                                    category.text =
                                        (selected.data()['name'] ?? '')
                                            .toString();
                                  });
                                },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: category,
                          decoration: const InputDecoration(
                            labelText: 'Category name',
                            helperText:
                                'Selecting a category above also saves its category ID.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sizes,
                  decoration: const InputDecoration(
                    labelText: 'Available sizes',
                    helperText: 'Separate sizes with commas, e.g. S, M, L, XL.',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: delivery,
                  decoration: const InputDecoration(labelText: 'Delivery text'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: image,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Image URL(s)',
                    helperText:
                        'Separate multiple image URLs with commas. The first URL is also saved to the legacy image field.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save Product'),
          ),
        ],
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
  Widget build(BuildContext context) => _PageFrame(
        title: 'Inventory',
        subtitle: 'Track available quantities separately for every product size.',
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('Products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Could not load products.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            var configured = 0;
            var units = 0;
            var low = 0;
            var out = 0;
            for (final doc in docs) {
              final data = doc.data();
              final sizes = data['sizes'] is List
                  ? (data['sizes'] as List).map((e) => e.toString()).toList()
                  : <String>[];
              final stock = data['stockBySize'] is Map
                  ? Map<String, dynamic>.from(data['stockBySize'] as Map)
                  : <String, dynamic>{};
              final limit = (data['lowStockThreshold'] as num?)?.toInt() ?? 5;
              if (sizes.isNotEmpty && sizes.every((s) => stock[s] is num)) configured++;
              for (final size in sizes) {
                final count = (stock[size] as num?)?.toInt();
                if (count == null) continue;
                units += count;
                if (count == 0) {
                  out++;
                } else if (count <= limit) {
                  low++;
                }
              }
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Kpi(title: 'Products', value: docs.length.toString(), icon: Icons.inventory_2_outlined),
                    _Kpi(title: 'Configured', value: configured.toString(), icon: Icons.fact_check_outlined),
                    _Kpi(title: 'Total units', value: units.toString(), icon: Icons.stacked_bar_chart),
                    _Kpi(title: 'Low / out sizes', value: '$low / $out', icon: Icons.warning_amber_outlined),
                  ],
                ),
                const SizedBox(height: 14),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: _blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Stock is stored in Products.stockBySize. Existing quantities are not guessed; products begin as Not configured. This milestone adds admin stock entry and monitoring only. Checkout blocking and automatic deduction require a separate trusted server-side order workflow.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No products found.')))
                else
                  ...docs.map((doc) => _InventoryProductCard(productId: doc.id, data: doc.data())),
              ],
            );
          },
        ),
      );
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({required this.productId, required this.data});
  final String productId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final sizes = data['sizes'] is List
        ? (data['sizes'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final stock = data['stockBySize'] is Map
        ? Map<String, dynamic>.from(data['stockBySize'] as Map)
        : <String, dynamic>{};
    final threshold = (data['lowStockThreshold'] as num?)?.toInt() ?? 5;
    final configured = sizes.isNotEmpty && sizes.every((s) => stock[s] is num);
    final total = sizes.fold<int>(0, (sum, s) => sum + ((stock[s] as num?)?.toInt() ?? 0));
    final imageUrl = (data['image'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: imageUrl.startsWith('http')
                        ? Image.network(imageUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined))
                        : const Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((data['name'] ?? 'Unnamed product').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(_money(data['price']) + ' • ' + sizes.length.toString() + ' sizes', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(configured ? '$total units' : 'Not configured',
                    style: TextStyle(color: configured ? Colors.green : Colors.orange, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            if (sizes.isEmpty)
              const Text('No sizes are saved for this product. Add sizes in Products before setting stock.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sizes.map((size) {
                  final count = (stock[size] as num?)?.toInt();
                  final color = count == null ? Colors.orange : count == 0 ? Colors.red : count <= threshold ? Colors.deepOrange : Colors.green;
                  return Chip(
                    avatar: Icon(Icons.straighten, size: 16, color: color),
                    label: Text(count == null ? '$size: Not set' : '$size: $count'),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(configured ? 'Low-stock alert: $threshold per size' : 'Enter the real quantity for each size',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                FilledButton.tonalIcon(
                  onPressed: sizes.isEmpty ? null : () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => _InventoryEditorDialog(
                        productName: (data['name'] ?? 'Product').toString(),
                        sizes: sizes,
                        initialStock: stock,
                        initialThreshold: threshold,
                      ),
                    );
                    if (result == null) return;
                    try {
                      await _db.collection('Products').doc(productId).update({
                        'stockBySize': result['stockBySize'],
                        'lowStockThreshold': result['lowStockThreshold'],
                        'inventoryUpdatedAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) _message(context, 'Inventory updated.');
                    } catch (error) {
                      if (context.mounted) _message(context, 'Could not update inventory: $error');
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Manage stock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryEditorDialog extends StatefulWidget {
  const _InventoryEditorDialog({required this.productName, required this.sizes, required this.initialStock, required this.initialThreshold});
  final String productName;
  final List<String> sizes;
  final Map<String, dynamic> initialStock;
  final int initialThreshold;

  @override
  State<_InventoryEditorDialog> createState() => _InventoryEditorDialogState();
}

class _InventoryEditorDialogState extends State<_InventoryEditorDialog> {
  late final Map<String, TextEditingController> controllers = {
    for (final size in widget.sizes)
      size: TextEditingController(text: widget.initialStock[size]?.toString() ?? ''),
  };
  late final threshold = TextEditingController(text: widget.initialThreshold.toString());
  String? error;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    threshold.dispose();
    super.dispose();
  }

  void save() {
    final limit = int.tryParse(threshold.text.trim());
    if (limit == null || limit < 0) {
      setState(() => error = 'Enter a valid non-negative alert threshold.');
      return;
    }
    final quantities = <String, int>{};
    for (final entry in controllers.entries) {
      final count = int.tryParse(entry.value.text.trim());
      if (count == null || count < 0) {
        setState(() => error = 'Enter a whole number (0 or more) for size ' + entry.key + '.');
        return;
      }
      quantities[entry.key] = count;
    }
    Navigator.pop(context, {'stockBySize': quantities, 'lowStockThreshold': limit});
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Manage ' + widget.productName),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(alignment: Alignment.centerLeft, child: Text('Available quantity for each size')),
                const SizedBox(height: 12),
                ...controllers.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: entry.value,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Size ' + entry.key, hintText: 'Enter quantity'),
                      ),
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: threshold,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock alert threshold',
                    helperText: 'A size is low when quantity is above zero and at or below this value.',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: Text(error!, style: const TextStyle(color: Colors.red))),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: save, child: const Text('Save stock')),
        ],
      );
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
    final csv = ['Order ID,Customer,Status,Total EGP,Ordered At', ...rows].join('\n');
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
    Card(child: ListTile(title: Text('Suggested questions'), subtitle: Text('Which products are top sellers?\nHow many orders are pending?\nSummarize sales for the last 30 days.'))),
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
