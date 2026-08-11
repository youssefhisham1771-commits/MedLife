import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:cloudinary_public/cloudinary_public.dart';


final cloudinary = CloudinaryPublic(
  'dzlorraqi',
  'Medlife',
  cache: false,
);


class AddSaleScreen extends StatefulWidget {
  const AddSaleScreen({super.key});

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {

  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final discountController = TextEditingController();

  DateTime? expiryDate;

  bool isLoading = false;

  File? saleImageFile;
  String? uploadedImageUrl;
  String? selectedProductId;
  String? selectedProductName;
  double? selectedProductPrice;

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {

      setState(() {
        saleImageFile = File(picked.path);
      });

      /// ☁️ Upload To Cloudinary
      try {

        CloudinaryResponse response =
            await cloudinary.uploadFile(

          CloudinaryFile.fromFile(
            saleImageFile!.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );

        if (!mounted) return;

        uploadedImageUrl = response.secureUrl;

      } catch (e) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image Upload Failed ❌"),
          ),
        );
      }
    }
  }

  /// 📅 PICK DATE
  Future<void> pickDate() async {

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {

      setState(() {
        expiryDate = picked;
      });
    }
  }

  /// 🔥 ADD SALE
  Future<void> addSale() async {

    if (
        selectedProductId == null ||
        selectedProductPrice == null ||
        uploadedImageUrl == null ||
        titleController.text.trim().isEmpty ||
        detailsController.text.trim().isEmpty ||
        discountController.text.trim().isEmpty ||
        expiryDate == null
    ) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete all fields"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      await FirebaseFirestore.instance
          .collection('sales')
          .add({
        "image": uploadedImageUrl,

        "productId": selectedProductId,

"productName": selectedProductName,

'price': selectedProductPrice,

        "title": titleController.text.trim(),

        "details": detailsController.text.trim(),

        "discount":
            int.parse(discountController.text.trim()),

        "expiryDate": Timestamp.fromDate(expiryDate!),

        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sale Added 🔥"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error ❌"),
        ),
      );
    }

    if (mounted) {
  setState(() {
    isLoading = false;
  });
}
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Add Sale 🔥"),
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 📸 IMAGE
            const Text(
              "Sale Image",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(

              onTap: pickImage,

              child: Container(

                height: 200,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),

                child: saleImageFile == null

                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Choose Sale Image",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )

                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),

                        child: Image.file(
                          saleImageFile!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            /// 🛍 SELECT PRODUCT
const Text(
  "Choose Product",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('Products')
      .snapshots(),

  builder: (context, snapshot) {

    if (!snapshot.hasData) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    var products = snapshot.data!.docs;

    return DropdownButtonFormField(

      initialValue: selectedProductId,

      items: products.map((product) {

        final data = product.data();

        return DropdownMenuItem(

          value: product.id,

          child: Text(
            data['name'] ?? "",
          ),
        );

      }).toList(),

      onChanged: (value) {

        var selected = products.firstWhere(
          (p) => p.id == value,
        );

        final data = selected.data();

        setState(() {

  selectedProductId = selected.id;

  selectedProductName = data['name'];

  selectedProductPrice =
      (data['price'] as num).toDouble();
});
      },

      decoration: InputDecoration(

        hintText: "Choose Product",

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  },
),

const SizedBox(height: 25),

            /// 📝 TITLE
            TextField(
              controller: titleController,

              decoration: InputDecoration(
                labelText: "Sale Title",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📄 DETAILS
            TextField(
              controller: detailsController,
              maxLines: 4,

              decoration: InputDecoration(
                labelText: "Sale Details",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 💸 DISCOUNT
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                labelText: "Discount %",

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📅 DATE
            GestureDetector(

              onTap: pickDate,

              child: Container(

                width: double.infinity,

                padding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 18,
                ),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: Text(

                  expiryDate == null

                      ? "Choose Expiry Date"

                      : "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}",
                ),
              ),
            ),

            const SizedBox(height: 35),

            /// 🔥 BUTTON
            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                    isLoading ? null : addSale,

                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),

                child: isLoading

                    ? CircularProgressIndicator(
                        color: Color(0xFF6EA6C1),
                      )

                    : Text(
                        "Add Sale",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}