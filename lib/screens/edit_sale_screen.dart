import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSaleScreen extends StatefulWidget {

  final String saleId;

  final Map<String, dynamic> saleData;

const EditSaleScreen({
  super.key,
  required this.saleId,
  required this.saleData,
});

  @override
  State<EditSaleScreen> createState() =>
      _EditSaleScreenState();
}

class _EditSaleScreenState
    extends State<EditSaleScreen> {

  late TextEditingController titleController;

  late TextEditingController detailsController;

  late TextEditingController discountController;

  bool isLoading = false;

  @override
  void initState() {

    super.initState();

    titleController =
        TextEditingController(
      text: widget.saleData['title'],
    );

    detailsController =
        TextEditingController(
      text: widget.saleData['details'],
    );

    discountController =
        TextEditingController(
      text: widget.saleData['discount']
          .toString(),
    );
  }

  Future<void> updateSale() async {

    final discount = int.tryParse(
  discountController.text.trim(),
);

if (discount == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Enter a valid discount"),
    ),
  );
  return;
}

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection('sales')
        .doc(widget.saleId)
        .update({

      "title":
          titleController.text.trim(),

      "details":
          detailsController.text.trim(),

      "discount":
          int.parse(
            discountController.text.trim(),
          ),
    });

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(
        content: Text("Sale Updated 🔥"),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Sale"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(

              controller: titleController,

              decoration: const InputDecoration(
                labelText: "Sale Title",
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: detailsController,

              maxLines: 4,

              decoration: const InputDecoration(
                labelText: "Sale Details",
              ),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: discountController,

              keyboardType:
                  TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Discount %",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(

              onPressed:
                  isLoading
                      ? null
                      : updateSale,

              child:
                  isLoading
                      ? CircularProgressIndicator()
                      : Text("Update Sale"),
            ),
          ],
        ),
      ),
    );
  }
  @override
void dispose() {
  titleController.dispose();
  detailsController.dispose();
  discountController.dispose();
  super.dispose();
}
}