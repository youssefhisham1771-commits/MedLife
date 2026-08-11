import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';


class AddEditProductScreen extends StatefulWidget {
  final String? docId;
  final dynamic oldData;

const AddEditProductScreen({
  super.key,
  this.docId,
  this.oldData,
});

  @override
  State<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState
    extends State<AddEditProductScreen> {

  final name = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  final deliveryText = TextEditingController();


  List<String> imageUrls = [];

  bool isLoading = false;

  final Color primaryColor = const Color(0xFF6EA6C1);

  @override
  void initState() {
    super.initState();

    if (widget.oldData != null) {

      name.text =
          widget.oldData['name']?.toString() ?? "";

      price.text =
          widget.oldData['price']?.toString() ?? "";

      description.text =
          widget.oldData['description']?.toString() ?? "";

      deliveryText.text =
    widget.oldData['deliveryText']?.toString() ?? "";

      if (widget.oldData['images'] != null) {

        imageUrls =
            List<String>.from(
                widget.oldData['images']);
      }
    }
  }

  ////////////////// IMAGE //////////////////

  Future<void> pickAndUploadImage() async {

    final picker = ImagePicker();

    final XFile? pickedFile =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    setState(() {
      isLoading = true;
    });

    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.cloudinary.com/v1_1/dzlorraqi/image/upload',
        ),
      );

      request.fields['upload_preset'] = 'Medlife';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pickedFile.path,
        ),
      );

      var response = await request.send();

      var responseData =
          await response.stream.bytesToString();

      var data = jsonDecode(responseData);

      if (!mounted) return;

      if (data['secure_url'] != null) {

        setState(() {

          imageUrls.add(
            data['secure_url'],
          );
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              "Image Uploaded Successfully ✅",
            ),
          ),
        );
      }

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Upload Failed ❌",
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  ////////////////// SAVE PRODUCT //////////////////

  Future<void> saveProduct() async {

    if (name.text.isEmpty ||
        price.text.isEmpty ||
        description.text.isEmpty ||
        imageUrls.isEmpty ||
deliveryText.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Please complete all fields",
          ),
        ),
      );

      return;
    }

    var data = {

      "name":
          name.text.trim(),

      "price":
          price.text.trim(),

      "description":
          description.text.trim(),

      "deliveryText":
    deliveryText.text.trim(),

      "images":
          imageUrls,

      "createdAt": Timestamp.now(),
    };

    if (widget.docId == null) {

      await FirebaseFirestore.instance
          .collection('Products')
          .add(data);

          if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Product Added ✅",
          ),
        ),
      );

    } else {

      await FirebaseFirestore.instance
          .collection('Products')
          .doc(widget.docId)
          .update(data);

          if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Product Updated ✅",
          ),
        ),
      );
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  ////////////////// UI //////////////////

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFF0B0713),

      appBar: AppBar(

        backgroundColor:
            Colors.transparent,

        elevation: 0,

        title: Text(

          widget.docId == null
              ? "Add Product"
              : "Edit Product",

          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            ////////////////// PRODUCT NAME //////////////////

            buildLabel("Product Name"),

            SizedBox(height: 10),

            buildTextField(
              controller: name,
              hint:
                  "Enter product name",
              icon:
                  Icons.shopping_bag_outlined,
            ),

            SizedBox(height: 22),

            ////////////////// PRICE //////////////////

            buildLabel("Price (EGP)"),

            SizedBox(height: 10),

            buildTextField(
              controller: price,
              hint:
                  "Enter product price",
              icon:
                  Icons.local_offer_outlined,
              keyboard:
                  TextInputType.number,
            ),

            SizedBox(height: 25),

            ////////////////// IMAGE //////////////////

            GestureDetector(

              onTap:
                  pickAndUploadImage,

              child: Container(

                width: double.infinity,

                padding:
                    EdgeInsets.symmetric(
                  vertical: 35,
                ),

                decoration:
                    BoxDecoration(

                  color:
                      Colors.white
                          .withValues(alpha: 0.03),

                  borderRadius:
                      BorderRadius
                          .circular(
                              24),

                  border: Border.all(
                    color: primaryColor
                        .withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),

                child: Column(

                  children: [

                    Container(

                      padding:
                          EdgeInsets.all(
                              18),

                      decoration:
                          BoxDecoration(

                        shape:
                            BoxShape.circle,

                        color: primaryColor
                            .withValues(alpha: 0.12)
                      ),

                      child: Icon(
                        Icons
                            .cloud_upload_outlined,

                        color:
                            primaryColor,

                        size: 34,
                      ),
                    ),

                    SizedBox(height: 18),

                    Text(

                      "Upload Product Image",

                      style: TextStyle(
                        color:
                            primaryColor,
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(

                      "JPG, PNG up to 5MB",

                      style: TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            ////////////////// LOADING //////////////////

            if (isLoading)
              Center(
                child:
                    CircularProgressIndicator(
                  color:
                      primaryColor,
                ),
              ),

            ////////////////// IMAGES //////////////////

            Wrap(

              spacing: 12,
              runSpacing: 12,

              children:
                  imageUrls.map((url) {

                return Stack(

                  children: [

                    ClipRRect(

                      borderRadius:
                          BorderRadius
                              .circular(
                                  18),

                      child:
                          Image.network(

                        url,

                        width: 110,
                        height: 110,

                        fit:
                            BoxFit.cover,
                      ),
                    ),

                    Positioned(

                      top: 5,
                      right: 5,

                      child:
                          GestureDetector(

                        onTap: () {

                          setState(() {

                            imageUrls
                                .remove(
                                    url);
                          });
                        },

                        child:
                            Container(

                          padding:
                              EdgeInsets
                                  .all(5),

                          decoration:
                              BoxDecoration(

                            color:
                                Colors.red,

                            shape:
                                BoxShape
                                    .circle,
                          ),

                          child: Icon(

                            Icons.close,

                            color:
                                Colors.white,

                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),

            SizedBox(height: 28),

            ////////////////// DESCRIPTION //////////////////

            buildLabel("Description"),

            SizedBox(height: 10),

            Container(

              decoration:
                  BoxDecoration(

                color:
                    Colors.white
                        .withValues(alpha: 0.03),

                borderRadius:
                    BorderRadius
                        .circular(22),

                border: Border.all(
                  color:
                      Colors.white10,
                ),
              ),

              child: TextField(

                controller:
                    description,

                maxLines: 6,
                maxLength: 500,

                style: TextStyle(
                  color:
                      Colors.white,
                ),

                decoration:
                    InputDecoration(

                  border:
                      InputBorder.none,

                  contentPadding:
                      EdgeInsets.all(
                          20),

                  hintText:
                      "Enter product description",

                  hintStyle:
                      TextStyle(
                    color:
                        Colors.white38,
                  ),

                  prefixIcon:
                      Padding(

                    padding:
                        EdgeInsets.only(
                            bottom: 95),

                    child: Icon(
                      Icons
                          .description_outlined,

                      color:
                          primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

           ////////////////// DELIVERY INFO //////////////////

buildLabel("Delivery Info"),

SizedBox(height: 10),

buildTextField(

  controller: deliveryText,

  hint: "ُEnter Delivery Duration",

  icon: Icons.local_shipping_outlined,
),

SizedBox(height: 18),

            ////////////////// INFO BOX //////////////////

            Container(

              width: double.infinity,

              padding:
                  EdgeInsets.all(16),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white
                        .withValues(alpha: 0.04),

                borderRadius:
                    BorderRadius
                        .circular(18),
              ),

              child: Row(

                children: [

                  Icon(
                    Icons.info_outline,
                    color:
                        primaryColor,
                  ),

                  SizedBox(width: 12),

                  Expanded(

                    child: Text(

                      "Customers will see this date as the estimated delivery time",

                      style: TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 35),

            ////////////////// BUTTON //////////////////

            SizedBox(

              width: double.infinity,
              height: 62,

              child: ElevatedButton(

                onPressed:
                    saveProduct,

                style:
                    ElevatedButton
                        .styleFrom(

                  backgroundColor:
                      primaryColor,

                  shape:
                      RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius
                            .circular(
                                22),
                  ),
                ),

                child: Text(

                  widget.docId == null
                      ? "Add Product"
                      : "Update Product",

                  style: TextStyle(

                    color:
                        Colors.white,

                    fontSize: 20,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  ////////////////// REUSABLE //////////////////

  Widget buildLabel(String text) {

    return Text(

      text,

      style: TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight:
            FontWeight.w500,
      ),
    );
  }

  Widget buildTextField({

    required TextEditingController controller,

    required String hint,

    required IconData icon,

    TextInputType keyboard =
        TextInputType.text,

  }) {

    return Container(

      decoration: BoxDecoration(

        color:
            Colors.white.withValues(alpha: 0.03),

        borderRadius:
            BorderRadius.circular(
                20),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboard,

        style: TextStyle(
          color: Colors.white,
        ),

        decoration: InputDecoration(

          border: InputBorder.none,

          contentPadding:
              EdgeInsets.symmetric(
            vertical: 22,
          ),

          hintText: hint,

          hintStyle: TextStyle(
            color: Colors.white38,
          ),

          prefixIcon: Container(

            margin: EdgeInsets.all(10),

            decoration: BoxDecoration(

              color:
                  primaryColor
                      .withValues(alpha: 0.12),

              borderRadius:
                  BorderRadius
                      .circular(
                          14),
            ),

            child: Icon(
              icon,
              color:
                  primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    name.dispose();
    price.dispose();
    description.dispose();
    deliveryText.dispose();

    super.dispose();
  }
}