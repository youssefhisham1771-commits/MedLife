import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_edit_category_screen.dart';

class CategoriesScreen extends StatelessWidget {
  final bool isAdmin;
  const CategoriesScreen({super.key, required this.isAdmin});
  static const Color _blue = Color(0xFF59C7FF);

  Future<void> _deleteCategory(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> category) async {
    final data = category.data();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111D31),
        title: const Text('Delete category?', style: TextStyle(color: Colors.white)),
        content: Text('Products assigned to "${data['name']}" will remain in the store but become uncategorized.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = FirebaseFirestore.instance;
    final byId = await db.collection('Products').where('categoryId', isEqualTo: category.id).get();
    final byName = await db.collection('Products').where('category', isEqualTo: data['name']).get();
    final linked = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in [...byId.docs, ...byName.docs]) { linked[doc.id] = doc; }
    final batch = db.batch();
    for (final doc in linked.values) {
      batch.update(doc.reference, {'categoryId': FieldValue.delete(), 'category': FieldValue.delete()});
    }
    batch.delete(category.reference);
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080F1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        backgroundColor: _blue, foregroundColor: const Color(0xFF071426),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen())),
        child: const Icon(Icons.add_rounded, size: 30),
      ) : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Could not load categories', style: TextStyle(color: Colors.white70)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _blue));
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 92, height: 92,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _blue.withValues(alpha: .10),
                        border: Border.all(color: _blue.withValues(alpha: .45))),
                      child: const Icon(Icons.category_outlined, color: _blue, size: 43)),
                    const SizedBox(height: 18),
                    const Text('No categories yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(isAdmin ? 'Add your first category to organize products.' : 'Categories will appear here when the admin adds them.',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditCategoryScreen())),
                        icon: const Icon(Icons.add), label: const Text('Add Category'),
                        style: FilledButton.styleFrom(backgroundColor: _blue, foregroundColor: const Color(0xFF071426))),
                    ],
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .95),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final icon = IconData(data['iconCodePoint'] is int ? data['iconCodePoint'] as int : Icons.category_outlined.codePoint,
                fontFamily: data['iconFontFamily']?.toString() ?? 'MaterialIcons');
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFF10233F), Color(0xFF09172C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: const Color(0xFF367EBA)),
                  boxShadow: [BoxShadow(color: _blue.withValues(alpha: .12), blurRadius: 14, spreadRadius: 1)]),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(icon, color: _blue, size: 58))
                              : Icon(icon, color: _blue, size: 58)),
                            const SizedBox(height: 10),
                            Text(data['name']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    if (isAdmin) Positioned(
                      top: 5, right: 5,
                      child: PopupMenuButton<String>(
                        color: const Color(0xFF111D31),
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AddEditCategoryScreen(docId: doc.id, oldData: data)));
                          } else if (value == 'delete') {
                            await _deleteCategory(context, doc);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                          PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
