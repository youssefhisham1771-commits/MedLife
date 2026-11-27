import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'orders_management_page.dart';
import 'customers_management_page.dart';
import 'finance_reports_page.dart';

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
  const AdminModulePage({
    super.key,
    required this.index,
    required this.isSuperAdmin,
    required this.permissions,
  });

  final int index;
  final bool isSuperAdmin;
  final Set<String> permissions;

  bool can(String permission) =>
      isSuperAdmin || permissions.contains(permission);

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1:
        return OrdersManagementPage(canUpdate: can('orders.update'));
      case 2:
        return ProductsAdminPage(
          canCreate: can('products.create'),
          canUpdate: can('products.update'),
          canDelete: can('products.delete'),
        );
      case 3:
        return InventoryAdminPage(canManage: can('inventory.manage'));
      case 4:
        return const CustomersManagementPage();
      case 5:
        return const CategoriesAdminPage();
      case 6:
        return const BannersAdminPage();
      case 7:
        return const AnalyticsAdminPage();
      case 8:
        return const FinanceReportsPage();
      case 9:
        return const StaffAdminPage();
      case 10:
        return const NotificationsAdminPage();
      case 11:
        return const AssistantAdminPage();
      case 12:
        return const SettingsAdminPage();
      case 13:
        return const ActivityAdminPage();
      case 14:
        return const BackupAdminPage();
      default:
        return const Center(child: Text('Select a module'));
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
  const ProductsAdminPage({
    super.key,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
  });

  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

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
    action: widget.canCreate
        ? FilledButton.icon(
            onPressed: () => editProduct(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          )
        : null,
    child: Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(onChanged: (v) => setState(() => search = v.toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search products by name or category'))),
      const SizedBox(height: 12),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('Products').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Could not load Products collection.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs.where((d) => d.data().toString().toLowerCase().contains(search)).toList()
            ..sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];
              DateTime? dateOf(dynamic value) {
                if (value is Timestamp) return value.toDate();
                if (value is DateTime) return value;
                return null;
              }
              return (dateOf(bDate) ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(dateOf(aDate) ?? DateTime.fromMillisecondsSinceEpoch(0));
            });
          if (docs.isEmpty) return const Center(child: Text('No products found.'));
          return ListView.separated(padding: const EdgeInsets.all(24), itemCount: docs.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (context, i) {
            final doc = docs[i]; final d = doc.data(); final images = (d['images'] as List?) ?? []; final image = images.isNotEmpty ? images.first.toString() : (d['image'] ?? '').toString();
            return Card(child: ListTile(
              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: image.startsWith('http') ? Image.network(image, width: 52, height: 58, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 52, child: Icon(Icons.image_not_supported))) : const SizedBox(width: 52, child: Icon(Icons.inventory_2))),
              title: Text((d['name'] ?? 'Unnamed product').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_money(d['price'])} • ${d['category'] ?? 'Uncategorized'}'),
              trailing: (widget.canUpdate || widget.canDelete)
                  ? PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit' && widget.canUpdate) {
                          await editProduct(doc);
                        }
                        if (v == 'delete' && widget.canDelete) {
                          final yes = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete product?'),
                              content: Text('Delete ${d['name'] ?? 'this product'} from the store?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (yes == true) {
                            try {
                              await doc.reference.delete();
                              if (context.mounted) _message(context, 'Product deleted.');
                            } catch (e) {
                              if (context.mounted) _message(context, 'Delete failed: $e');
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (widget.canUpdate)
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        if (widget.canDelete)
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
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

  Future<void> save(List<QueryDocumentSnapshot<Map<String, dynamic>>> categories) async {
    final parsedPrice = double.tryParse(price.text.trim());
    if (name.text.trim().isEmpty ||
        parsedPrice == null ||
        !parsedPrice.isFinite ||
        parsedPrice < 0) {
      _message(context, 'Enter a product name and a valid non-negative price.');
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? categoryDoc;
    for (final doc in categories) {
      final matchesSelectedId =
          selectedCategoryId != null && doc.id == selectedCategoryId;
      final matchesLegacyName = selectedCategoryId == null &&
          (doc.data()['name'] ?? '').toString().trim().toLowerCase() ==
              (widget.initial?['category'] ?? '').toString().trim().toLowerCase();
      if (matchesSelectedId || matchesLegacyName) {
        categoryDoc = doc;
        break;
      }
    }
    if (categoryDoc == null) {
      _message(context, 'Select an existing category before saving this product.');
      return;
    }

    final images = image.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    for (final value in images) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty) {
        _message(context, 'Each product image must be a valid HTTP or HTTPS URL.');
        return;
      }
    }

    final productSizes = sizes.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    setState(() => saving = true);
    try {
      final categoryName = (categoryDoc.data()['name'] ?? '').toString().trim();
      final data = <String, dynamic>{
        'name': name.text.trim(),
        'price': parsedPrice,
        'description': description.text.trim(),
        'deliveryText': delivery.text.trim(),
        'category': categoryName,
        'categoryId': categoryDoc.id,
        'images': images,
        'image': images.isEmpty ? '' : images.first,
        'sizes': productSizes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.initial == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('Products').add(data);
      } else {
        await _db.collection('Products').doc(widget.documentId).update(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _message(context, 'Could not save product: $error');
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
    sizes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('categories').snapshots(),
        builder: (context, snapshot) {
          final categories = snapshot.data?.docs ?? [];
          String? dropdownValue = selectedCategoryId;
          if (dropdownValue == null) {
            for (final doc in categories) {
              if ((doc.data()['name'] ?? '').toString().trim().toLowerCase() ==
                  (widget.initial?['category'] ?? '').toString().trim().toLowerCase()) {
                dropdownValue = doc.id;
                break;
              }
            }
          }
          if (dropdownValue != null &&
              !categories.any((doc) => doc.id == dropdownValue)) {
            dropdownValue = null;
          }

          return AlertDialog(
            title: Text(widget.initial == null ? 'Add Product' : 'Edit Product'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Product name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: price,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (EGP)',
                        prefixText: 'EGP ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (snapshot.hasError)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Could not load categories. Check your access and connection.'),
                      )
                    else if (!snapshot.hasData)
                      const LinearProgressIndicator()
                    else if (categories.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Create a category first from the Categories page.'),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: dropdownValue,
                        decoration: const InputDecoration(
                          labelText: 'Product category',
                          helperText: 'Choose one of the categories managed in the Categories page.',
                        ),
                        items: categories.map((doc) => DropdownMenuItem<String>(
                          value: doc.id,
                          child: Text((doc.data()['name'] ?? 'Unnamed').toString()),
                        )).toList(),
                        onChanged: saving ? null : (value) {
                          setState(() => selectedCategoryId = value);
                        },
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sizes,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Available sizes',
                        helperText: 'Separate sizes with commas, e.g. S, M, L, XL.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: delivery,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Delivery text'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: image,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Product image URL(s)',
                        helperText: 'Use full HTTP/HTTPS URLs. Separate multiple images with commas.',
                      ),
                    ),
                    if (image.text.trim().startsWith('https://')) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Image preview is shown in the product list after saving.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
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
                onPressed: saving || !snapshot.hasData || categories.isEmpty
                    ? null
                    : () => save(categories),
                child: Text(saving ? 'Saving…' : 'Save Product'),
              ),
            ],
          );
        },
      );
}
class CategoriesAdminPage extends StatefulWidget {
  const CategoriesAdminPage({super.key});

  @override
  State<CategoriesAdminPage> createState() => _CategoriesAdminPageState();
}

class _CategoriesAdminPageState extends State<CategoriesAdminPage> {
  static const List<IconData> _categoryIcons = [
    Icons.category_outlined,
    Icons.checkroom_rounded,
    Icons.medical_services_outlined,
    Icons.medical_information_outlined,
    Icons.construction_rounded,
    Icons.shopping_bag_outlined,
    Icons.sell_outlined,
    Icons.health_and_safety_outlined,
    Icons.science_outlined,
    Icons.workspace_premium_outlined,
    Icons.local_hospital_outlined,
    Icons.inventory_2_outlined,
    Icons.cleaning_services_outlined,
    Icons.biotech_outlined,
    Icons.assignment_outlined,
    Icons.dental_services_outlined,
  ];

  Future<void> _edit(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};
    final name = TextEditingController(text: data['name']?.toString() ?? '');
    final imageUrl = TextEditingController(
      text: data['imageUrl']?.toString() ?? '',
    );
    var iconCodePoint = data['iconCodePoint'] is num
        ? (data['iconCodePoint'] as num).toInt()
        : Icons.category_outlined.codePoint;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(doc == null ? 'Add Category' : 'Edit Category'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g. Scrubs',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Category icon'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryIcons.map((icon) {
                      final selected = icon.codePoint == iconCodePoint;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setDialogState(
                          () => iconCodePoint = icon.codePoint,
                        ),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? _blue.withValues(alpha: .14)
                                : Theme.of(dialogContext).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _blue
                                  : Theme.of(dialogContext).dividerColor,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: selected ? _blue : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                      hintText: 'https://...',
                      helperText:
                          'When provided, the storefront displays this image instead of the icon.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final categoryName = name.text.trim();
                      if (categoryName.isEmpty) {
                        _message(dialogContext, 'Enter a category name.');
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        final collection = _db.collection('categories');
                        final duplicate = await collection
                            .where('name', isEqualTo: categoryName)
                            .get();
                        if (duplicate.docs.any((item) => item.id != doc?.id)) {
                          throw StateError(
                            'A category with this name already exists.',
                          );
                        }

                        final payload = <String, dynamic>{
                          'name': categoryName,
                          'iconCodePoint': iconCodePoint,
                          'iconFontFamily': 'MaterialIcons',
                          'imageUrl': imageUrl.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        if (doc == null) {
                          final existing = await collection.get();
                          var highestOrder = -1;
                          for (final item in existing.docs) {
                            final value = item.data()['sortOrder'];
                            if (value is num && value.toInt() > highestOrder) {
                              highestOrder = value.toInt();
                            }
                          }
                          payload['sortOrder'] = highestOrder + 1;
                          payload['createdAt'] = FieldValue.serverTimestamp();
                          await collection.add(payload);
                        } else {
                          await doc.reference.update(payload);
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          _message(
                            dialogContext,
                            'Could not save category: ' + error.toString(),
                          );
                          setDialogState(() => saving = false);
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Category'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    imageUrl.dispose();
    if (saved == true && context.mounted) {
      _message(context, doc == null ? 'Category added.' : 'Category updated.');
    }
  }

  Future<void> _move(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int index,
    int direction,
  ) async {
    final target = index + direction;
    if (target < 0 || target >= docs.length) return;

    final reordered = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      docs,
    );
    final moved = reordered.removeAt(index);
    reordered.insert(target, moved);

    try {
      final batch = _db.batch();
      for (var i = 0; i < reordered.length; i++) {
        batch.update(reordered[i].reference, {'sortOrder': i});
      }
      await batch.commit();
      if (context.mounted) _message(context, 'Category order updated.');
    } catch (error) {
      if (context.mounted) {
        _message(context, 'Could not reorder categories: ' + error.toString());
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final categoryName = (doc.data()['name'] ?? 'this category').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "' + categoryName + '"? Existing products will not be deleted. '
          'Their saved category text may remain until those products are edited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await doc.reference.delete();
      if (context.mounted) _message(context, 'Category deleted.');
    } catch (error) {
      if (context.mounted) {
        _message(context, 'Could not delete category: ' + error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        title: 'Categories',
        subtitle:
            'Manage the same categories used by the MedLife storefront, including icons, images and display order.',
        action: FilledButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('categories').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load categories.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final orderA = (a.data()['sortOrder'] as num?)?.toInt() ??
                    1 << 30;
                final orderB = (b.data()['sortOrder'] as num?)?.toInt() ??
                    1 << 30;
                final byOrder = orderA.compareTo(orderB);
                if (byOrder != 0) return byOrder;
                return (a.data()['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .compareTo(
                      (b.data()['name'] ?? '').toString().toLowerCase(),
                    );
              });

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 52,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text('No categories yet.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create first category'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final image = (data['imageUrl'] ?? '').toString();
                final iconCodePoint =
                    (data['iconCodePoint'] as num?)?.toInt() ??
                        Icons.category_outlined.codePoint;
                final icon = IconData(
                  iconCodePoint,
                  fontFamily:
                      data['iconFontFamily']?.toString() ?? 'MaterialIcons',
                );

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: image.startsWith('http')
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  icon,
                                  color: _blue,
                                  size: 30,
                                ),
                              )
                            : Icon(icon, color: _blue, size: 30),
                      ),
                    ),
                    title: Text(
                      (data['name'] ?? 'Unnamed category').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Order: ' +
                          (data['sortOrder'] ?? '—').toString() +
                          '  •  ID: ' +
                          doc.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          onPressed: index == 0
                              ? null
                              : () => _move(context, docs, index, -1),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          onPressed: index == docs.length - 1
                              ? null
                              : () => _move(context, docs, index, 1),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        IconButton(
                          tooltip: 'Edit category',
                          onPressed: () => _edit(context, doc: doc),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete category',
                          onPressed: () => _delete(context, doc),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
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
  const InventoryAdminPage({super.key, required this.canManage});

  final bool canManage;

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
                  ...docs.map((doc) => _InventoryProductCard(
                      productId: doc.id,
                      data: doc.data(),
                      canManage: canManage,
                    )),
              ],
            );
          },
        ),
      );
}

class _InventoryProductCard extends StatelessWidget {
  const _InventoryProductCard({
    required this.productId,
    required this.data,
    required this.canManage,
  });

  final String productId;
  final Map<String, dynamic> data;
  final bool canManage;

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
                if (canManage)
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

  double _amount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _orderDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  Widget build(BuildContext context) => _PageFrame(
        title: 'Analytics',
        subtitle: 'Live order, sales trend and product performance indicators.',
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db.collection('orders').snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText('Could not load analytics: ${snap.error}'),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            final activeDocs = docs.where((doc) =>
                (doc.data()['status'] ?? 'pending').toString().toLowerCase() !=
                'cancelled').toList();
            final orderValue = activeDocs.fold<double>(
              0,
              (sum, doc) => sum + _amount(doc.data()['total']),
            );
            final delivered = docs.where((doc) =>
                (doc.data()['status'] ?? '').toString().toLowerCase() ==
                'delivered').length;
            final pending = docs.where((doc) =>
                (doc.data()['status'] ?? 'pending').toString().toLowerCase() ==
                'pending').length;
            final averageOrder = activeDocs.isEmpty ? 0.0 : orderValue / activeDocs.length;

            const statusNames = [
              'pending',
              'processing',
              'shipped',
              'delivered',
              'cancelled',
            ];
            const statusColors = [
              Color(0xFFF59E0B),
              Color(0xFF8B5CF6),
              Color(0xFF3B82F6),
              Color(0xFF16A34A),
              Color(0xFFDC2626),
            ];
            final statusCounts = <String, int>{
              for (final status in statusNames)
                status: docs.where((doc) =>
                    (doc.data()['status'] ?? 'pending')
                        .toString()
                        .toLowerCase() == status).length,
            };

            final now = DateTime.now();
            final firstMonth = DateTime(now.year, now.month - 5, 1);
            final monthlyTotals = List<double>.filled(6, 0);
            for (final doc in activeDocs) {
              final date = _orderDate(doc.data()['orderedAt']);
              if (date == null) continue;
              final index = (date.year - firstMonth.year) * 12 +
                  date.month - firstMonth.month;
              if (index >= 0 && index < monthlyTotals.length) {
                monthlyTotals[index] += _amount(doc.data()['total']);
              }
            }
            final maxMonthly = monthlyTotals.fold<double>(
              0,
              (largest, value) => value > largest ? value : largest,
            );
            final monthLabels = List<String>.generate(6, (index) {
              final month = DateTime(firstMonth.year, firstMonth.month + index, 1);
              return DateFormat('MMM').format(month);
            });

            final productTotals = <String, double>{};
            for (final doc in activeDocs) {
              final items = doc.data()['items'];
              if (items is! List) continue;
              for (final rawItem in items) {
                if (rawItem is! Map) continue;
                final item = Map<String, dynamic>.from(rawItem);
                final name = (item['name'] ?? 'Unnamed product').toString();
                final quantity = _amount(item['quantity'] ?? 1);
                productTotals[name] = (productTotals[name] ?? 0) +
                    _amount(item['price']) * quantity;
              }
            }
            final topProducts = productTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final visibleProducts = topProducts.take(5).toList();
            final maxProductValue = visibleProducts.isEmpty
                ? 0.0
                : visibleProducts.first.value;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Kpi(
                      title: 'All Orders',
                      value: docs.length.toString(),
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _Kpi(
                      title: 'Gross Order Value*',
                      value: _money(orderValue),
                      icon: Icons.payments_outlined,
                    ),
                    _Kpi(
                      title: 'Delivered',
                      value: delivered.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    _Kpi(
                      title: 'Pending',
                      value: pending.toString(),
                      icon: Icons.pending_actions,
                    ),
                    _Kpi(
                      title: 'Average Active Order',
                      value: _money(averageOrder),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly order value',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last six calendar months, excluding cancelled orders.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 230,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxMonthly <= 0 ? 10 : maxMonthly * 1.2,
                              barTouchData: BarTouchData(enabled: true),
                              gridData: const FlGridData(
                                show: true,
                                drawVerticalLine: false,
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 54,
                                    getTitlesWidget: (value, meta) => Text(
                                      NumberFormat.compact().format(value),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= monthLabels.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          monthLabels[index],
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                for (var index = 0; index < monthlyTotals.length; index++)
                                  BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: monthlyTotals[index],
                                        width: 20,
                                        borderRadius: BorderRadius.circular(5),
                                        color: _blue,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (activeDocs.isEmpty)
                          const Center(child: Text('Monthly sales data will appear when orders arrive.')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order status breakdown',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Distribution of all orders by their current status.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (docs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No order status data yet.')),
                          )
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: 170,
                                height: 170,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 34,
                                    sections: [
                                      for (var index = 0; index < statusNames.length; index++)
                                        if (statusCounts[statusNames[index]]! > 0)
                                          PieChartSectionData(
                                            value: statusCounts[statusNames[index]]!.toDouble(),
                                            color: statusColors[index],
                                            title: statusCounts[statusNames[index]].toString(),
                                            radius: 42,
                                            titleStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 14,
                                runSpacing: 10,
                                children: [
                                  for (var index = 0; index < statusNames.length; index++)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: statusColors[index],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${toBeginningOfSentenceCase(statusNames[index])}: ${statusCounts[statusNames[index]]}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top products by order value',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Based on item price multiplied by quantity in non-cancelled orders.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        if (visibleProducts.isEmpty)
                          const Text('Product performance will appear when orders include item details.')
                        else
                          ...visibleProducts.map((entry) {
                            final progress = maxProductValue <= 0
                                ? 0.0
                                : (entry.value / maxProductValue).clamp(0.0, 1.0).toDouble();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(_money(entry.value)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(value: progress),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '*Gross order value is the sum of non-cancelled order totals. It may include shipping and is not accounting net revenue.',
                ),
              ],
            );
          },
        ),
      );
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

class StaffAdminPage extends StatefulWidget {
  const StaffAdminPage({super.key});
  @override
  State<StaffAdminPage> createState() => _StaffAdminPageState();
}

class _StaffAdminPageState extends State<StaffAdminPage> {
  String search = '';
  late Future<List<Map<String, dynamic>>> accountsFuture = _loadAccounts();
  bool saving = false;

  Future<List<Map<String, dynamic>>> _loadAccounts() async {
    final result = await FirebaseFunctions.instance.httpsCallable('listMedLifeAccounts').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final rows = (data['accounts'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
    rows.sort((a, b) => (a['name'] ?? a['email'] ?? a['uid'] ?? '')
        .toString().toLowerCase().compareTo(
          (b['name'] ?? b['email'] ?? b['uid'] ?? '').toString().toLowerCase()));
    return rows;
  }

  void _refresh() => setState(() => accountsFuture = _loadAccounts());

  Future<void> _manageAccount(Map<String, dynamic> data) async {
    if (saving) return;
    final uid = (data['uid'] ?? '').toString();
    if (uid.isEmpty) {
      _message(context, 'This account has no valid ID.');
      return;
    }
    final existing = (data['permissions'] as List? ?? const []).whereType<String>().toSet();
    final initialActive = data['role'] == 'staff' && data['active'] == true;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final selected = {...existing};
        var active = initialActive || data['role'] != 'staff';
        return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: Text(data['role'] == 'staff' ? 'Manage staff access' : 'Grant staff access'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((data['name'] ?? data['displayName'] ?? data['email'] ?? uid).toString(),
                    style: Theme.of(context).textTheme.titleMedium),
                Text((data['email'] ?? uid).toString(), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Staff account active'),
                  subtitle: const Text('Inactive staff immediately lose dashboard permissions.'),
                  value: active,
                  onChanged: (value) => setDialogState(() {
                    active = value;
                    if (!active) selected.clear();
                  }),
                ),
                const Divider(),
                Text('Assign permissions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                const Text('Grant only the access required for this person’s job. Firebase security rules and server functions enforce these permissions.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                ..._staffPermissionGroups.entries.map((group) => ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: Text(group.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                  children: group.value.map((permission) {
                    final key = permission['key']!;
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(permission['label']!),
                      subtitle: Text(key, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      value: selected.contains(key),
                      onChanged: !active ? null : (checked) => setDialogState(() {
                        if (checked == true) { selected.add(key); } else { selected.remove(key); }
                      }),
                    );
                  }).toList(),
                )),
                if (!active) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Enable the account to select permissions.', style: TextStyle(color: Colors.orange)),
                ),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, {
                'active': active, 'permissions': active ? selected.toList() : <String>[],
              }),
              icon: const Icon(Icons.save_outlined), label: const Text('Save access')),
          ],
        ));
      },
    );
    if (result == null || !mounted) return;
    setState(() => saving = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('setMedLifeStaffPermissions').call({
        'targetUid': uid,
        'active': result['active'] == true,
        'permissions': result['permissions'] as List<String>,
      });
      if (!mounted) return;
      _message(context, result['active'] == true
          ? 'Staff permissions saved. The user must sign in again or refresh their session.'
          : 'Staff access deactivated and permissions cleared.');
      _refresh();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _message(context, 'Could not update staff access (' + e.code + '): ' + (e.message ?? 'Unknown error'));
    } catch (e) {
      if (mounted) _message(context, 'Could not update staff access: ' + e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showAccountDetails(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? data['email'] ?? 'Account').toString();
    final permissions = (data['permissions'] as List? ?? const []).join(', ');
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(name),
      content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _staffDetail('Email', data['email'] ?? '—'),
          _staffDetail('Phone', data['phoneNumber'] ?? '—'),
          _staffDetail('Account ID', data['uid'] ?? '—'),
          _staffDetail('Role', data['role'] ?? 'user'),
          _staffDetail('Status', data['disabled'] == true ? 'Authentication disabled' :
            (data['active'] == true ? 'Active staff' : (data['role'] == 'staff' ? 'Inactive staff' : 'Customer'))),
          _staffDetail('Permissions', permissions.isEmpty ? 'None assigned' : permissions),
        ],
      ))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
    ));
  }

  Widget _staffDetail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 3), SelectableText(value.toString()),
    ]),
  );

  @override
  Widget build(BuildContext context) => _PageFrame(
    title: 'Staff & Permissions',
    subtitle: 'Manage account access, assign least-privilege permissions and deactivate staff.',
    action: IconButton(tooltip: 'Refresh accounts', onPressed: saving ? null : _refresh,
        icon: const Icon(Icons.refresh)),
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: accountsFuture,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load accounts from the secure admin service.'),
            const SizedBox(height: 8),
            SelectableText(snap.error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ]),
        ));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final allAccounts = snap.data!;
        final filtered = allAccounts.where((data) {
          final searchable = [data['name'], data['displayName'], data['email'],
            data['phoneNumber'], data['uid'], data['role']]
            .where((value) => value != null).join(' ').toLowerCase();
          return searchable.contains(search.trim().toLowerCase());
        }).toList();
        final staffCount = allAccounts.where((a) => a['role'] == 'staff').length;
        final activeCount = allAccounts.where((a) => a['role'] == 'staff' && a['active'] == true).length;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Wrap(spacing: 12, runSpacing: 8, children: [
              _Kpi(title: 'Registered Accounts', value: allAccounts.length.toString(), icon: Icons.people_outline),
              _Kpi(title: 'Staff Accounts', value: staffCount.toString(), icon: Icons.badge_outlined),
              _Kpi(title: 'Active Staff', value: activeCount.toString(), icon: Icons.verified_user_outlined),
              _Kpi(title: 'Search Results', value: filtered.length.toString(), icon: Icons.manage_search),
            ]),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name, email, phone or account ID',
              suffixIcon: search.isEmpty ? null : IconButton(
                tooltip: 'Clear search', onPressed: () => setState(() => search = ''),
                icon: const Icon(Icons.close)),
            ),
          )),
          const SizedBox(height: 8),
          Expanded(child: filtered.isEmpty
            ? Center(child: Text(allAccounts.isEmpty ? 'No registered accounts found.' : 'No accounts match your search.'))
            : ListView.separated(
              padding: const EdgeInsets.all(24), itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = filtered[index];
                final name = (data['name'] ?? data['displayName'] ?? data['email'] ?? 'Unnamed account').toString();
                final email = (data['email'] ?? 'No email recorded').toString();
                final phone = (data['phoneNumber'] ?? 'No phone recorded').toString();
                final isStaff = data['role'] == 'staff', isActive = data['active'] == true;
                return Card(child: ListTile(
                  leading: CircleAvatar(child: Icon(isStaff ? Icons.badge_outlined : Icons.person_outline)),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(email + '\n' + phone, maxLines: 2, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                    Chip(label: Text(isStaff ? (isActive ? 'Active staff' : 'Inactive staff') : 'Customer')),
                    IconButton(tooltip: 'View account details', onPressed: () => _showAccountDetails(data),
                        icon: const Icon(Icons.info_outline)),
                    OutlinedButton(
                      onPressed: saving || data['disabled'] == true ? null : () => _manageAccount(data),
                      child: Text(isStaff ? 'Manage' : 'Grant access')),
                  ]),
                ));
              },
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined, color: _blue),
              title: const Text('Protected staff administration'),
              subtitle: Text(saving ? 'Saving access changes…' :
                'Only the Super Admin can assign permissions. Users must refresh their authentication session after a change.'),
            ),
          )),
        ]);
      },
    ),
  );
}

const Map<String, List<Map<String, String>>> _staffPermissionGroups = {
  'Dashboard': [{'key': 'dashboard.view', 'label': 'View dashboard'}],
  'Orders & Customers': [
    {'key': 'orders.view', 'label': 'View orders'},
    {'key': 'orders.update', 'label': 'Update order fulfillment status'},
    {'key': 'customers.view', 'label': 'View customer profiles'},
  ],
  'Products & Inventory': [
    {'key': 'products.view', 'label': 'View products'},
    {'key': 'products.create', 'label': 'Create products'},
    {'key': 'products.update', 'label': 'Edit products'},
    {'key': 'products.delete', 'label': 'Delete products'},
    {'key': 'inventory.view', 'label': 'View inventory'},
    {'key': 'inventory.manage', 'label': 'Manage stock levels'},
  ],
  'Store Content': [
    {'key': 'categories.manage', 'label': 'Manage categories'},
    {'key': 'marketing.manage', 'label': 'Manage banners and promotions'},
  ],
  'Reports': [{'key': 'reports_finance.view', 'label': 'View analytics and finance reports'}],
  'Operations': [
    {'key': 'notifications.manage', 'label': 'Manage notifications'},
    {'key': 'settings.manage', 'label': 'Manage system settings'},
    {'key': 'activity_log.view', 'label': 'View activity log'},
    {'key': 'backup.manage', 'label': 'Manage backups'},
  ],
};

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
