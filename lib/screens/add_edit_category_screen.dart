import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? oldData;
  const AddEditCategoryScreen({super.key, this.docId, this.oldData});
  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  static const Color _blue = Color(0xFF59C7FF);
  static const List<IconData> _availableIcons = [
    Icons.category_outlined, Icons.checkroom_rounded, Icons.medical_services_outlined,
    Icons.medical_information_outlined, Icons.construction_rounded, Icons.shopping_bag_outlined,
    Icons.sell_outlined, Icons.health_and_safety_outlined, Icons.science_outlined,
    Icons.workspace_premium_outlined, Icons.local_hospital_outlined, Icons.brush_outlined,
    Icons.inventory_2_outlined, Icons.cleaning_services_outlined, Icons.biotech_outlined,
    Icons.assignment_outlined,
  ];
  final TextEditingController _nameController = TextEditingController();
  String? _imageUrl;
  int _iconCodePoint = Icons.category_outlined.codePoint;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.oldData;
    if (data != null) {
      _nameController.text = data['name']?.toString() ?? '';
      _imageUrl = data['imageUrl']?.toString();
      if (data['iconCodePoint'] is int) _iconCodePoint = data['iconCodePoint'] as int;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1600);
    if (picked == null) return;
    setState(() => _isUploading = true);
    try {
      final request = http.MultipartRequest('POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dzlorraqi/image/upload'))
        ..fields['upload_preset'] = 'Medlife'
        ..files.add(await http.MultipartFile.fromPath('file', picked.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      final result = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300 || result['secure_url'] == null) {
        throw Exception(result['error']?['message'] ?? 'Image upload failed');
      }
      if (!mounted) return;
      setState(() => _imageUrl = result['secure_url'].toString());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category image uploaded successfully')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $error')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a category name')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final collection = FirebaseFirestore.instance.collection('categories');
      final duplicate = await collection.where('name', isEqualTo: name).get();
      if (duplicate.docs.any((doc) => doc.id != widget.docId)) {
        throw Exception('A category with this name already exists');
      }
      final payload = <String, dynamic>{
        'name': name,
        'iconCodePoint': _iconCodePoint,
        'iconFontFamily': 'MaterialIcons',
        'imageUrl': _imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.docId == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(payload);
      } else {
        final oldName = widget.oldData?['name']?.toString();
        await collection.doc(widget.docId).update(payload);
        if (oldName != null && oldName != name) {
          final linked = await FirebaseFirestore.instance.collection('Products')
            .where('category', isEqualTo: oldName).get();
          final batch = FirebaseFirestore.instance.batch();
          for (final product in linked.docs) {
            batch.update(product.reference, {'category': name, 'categoryId': widget.docId});
          }
          if (linked.docs.isNotEmpty) await batch.commit();
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save category: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIcon = IconData(_iconCodePoint, fontFamily: 'MaterialIcons');
    return Scaffold(
      backgroundColor: const Color(0xFF080F1D),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        title: Text(widget.docId == null ? 'Add Category' : 'Edit Category',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Category Name', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 9),
          TextField(controller: _nameController, style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter category name', hintStyle: const TextStyle(color: Colors.white38),
              filled: true, fillColor: Colors.white.withValues(alpha: .04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: _blue)))),
          const SizedBox(height: 24),
          const Text('Choose an icon', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03),
              borderRadius: BorderRadius.circular(18), border: Border.all(color: _blue.withValues(alpha: .35))),
            child: Wrap(spacing: 10, runSpacing: 10, children: _availableIcons.map((icon) {
              final selected = icon.codePoint == _iconCodePoint;
              return InkWell(
                onTap: () => setState(() => _iconCodePoint = icon.codePoint),
                borderRadius: BorderRadius.circular(12),
                child: Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: selected ? _blue.withValues(alpha: .2) : Colors.white.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? _blue : Colors.white12)),
                  child: Icon(icon, color: selected ? _blue : Colors.white70, size: 25)),
              );
            }).toList()),
          ),
          const SizedBox(height: 24),
          const Text('Or upload a category image', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          InkWell(
            onTap: _isUploading ? null : _pickImage,
            borderRadius: BorderRadius.circular(18),
            child: Container(width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(18), border: Border.all(color: _blue.withValues(alpha: .4))),
              child: Column(children: [
                if (_imageUrl != null && _imageUrl!.isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(14),
                    child: Image.network(_imageUrl!, height: 145, width: double.infinity, fit: BoxFit.contain))
                else
                  const Icon(Icons.cloud_upload_outlined, color: _blue, size: 42),
                const SizedBox(height: 10),
                Text(_isUploading ? 'Uploading...' : 'Choose image from device',
                  style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)),
              ])),
          ),
          if (_isUploading || _isSaving) ...[
            const SizedBox(height: 18),
            const Center(child: CircularProgressIndicator(color: _blue)),
          ],
          const SizedBox(height: 30),
          SizedBox(width: double.infinity, height: 54,
            child: ElevatedButton(
              onPressed: _isUploading || _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: const Color(0xFF071426),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
              child: Text(widget.docId == null ? 'Add Category' : 'Save Changes',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)))),
        ]),
      ),
    );
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }
}
