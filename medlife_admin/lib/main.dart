import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedLife Admin',
      theme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int productsCount = 0;
  int ordersCount = 0;
  int usersCount = 0;
  int selectedIndex = 0;

  double revenue = 0;

  Uint8List? selectedImage;
String uploadedImageUrl = '';

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final products =
        await FirebaseFirestore.instance
            .collection('Products')
            .get();

    final orders =
        await FirebaseFirestore.instance
            .collection('orders')
            .get();

    final users =
        await FirebaseFirestore.instance
            .collection('users')
            .get();

    setState(() {
      productsCount = products.docs.length;
      ordersCount = orders.docs.length;
      usersCount = users.docs.length;
    });
  }

  Future<void> uploadToCloudinary() async {
  if (selectedImage == null) return;

  const cloudName = 'dzlorraqi';
  const uploadPreset = 'Medlife';

  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/dzlorraqi/image/upload',
  );

  final request = http.MultipartRequest(
    'POST',
    uri,
  );

  request.fields['upload_preset'] = uploadPreset;

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      selectedImage!,
      filename: 'product.jpg',
    ),
  );

  final response = await request.send();

  final data = jsonDecode(
    await response.stream.bytesToString(),
  );

  uploadedImageUrl = data['secure_url'];
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B1120),
      body: Row(
        children: [

          /// SIDEBAR
          Container(
            width: 250,
            color: const Color(0xff111827),
            child: Column(
              children: [

                const SizedBox(height: 30),

                const Text(
                  "MEDLIFE ADMIN",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                menuItem(Icons.dashboard, "Dashboard", 0),
menuItem(Icons.inventory_2, "Products", 1),
menuItem(Icons.shopping_cart, "Orders", 2),
menuItem(Icons.people, "Users", 3),
menuItem(Icons.discount, "Coupons", 4),
menuItem(Icons.local_offer, "Offers", 5),
              ],
            ),
          ),

Expanded(
  child: selectedIndex == 0
    ? buildDashboard()
    : selectedIndex == 1
        ? buildProductsPage()
        : selectedIndex == 2
    ? buildOrdersPage()
    : selectedIndex == 3
        ? buildUsersPage()
        : selectedIndex == 4
            ? buildCouponsPage()
            : const Center(
                child: Text(
                  "Coming Soon",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
              )
),
        ],
      ),
    );
  }

  Widget buildDashboard() {
  return Padding(
    padding: const EdgeInsets.all(30),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 30),

        Row(
          children: [

            dashboardCard(
              "Products",
              productsCount.toString(),
              Icons.inventory_2,
            ),

            const SizedBox(width: 20),

            dashboardCard(
              "Orders",
              ordersCount.toString(),
              Icons.shopping_cart,
            ),

            const SizedBox(width: 20),

            dashboardCard(
              "Users",
              usersCount.toString(),
              Icons.people,
            ),

            const SizedBox(width: 20),

            dashboardCard(
              "Revenue",
              "${revenue.toStringAsFixed(0)} EGP",
              Icons.attach_money,
            ),
          ],
        ),
      ],
    ),
  );
}

Widget buildProductsPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "Products",
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),

    ElevatedButton.icon(
      onPressed: () {
        showAddProductDialog(context);
      },
      icon: const Icon(Icons.add),
      label: const Text("Add Product"),
    ),
  ],
),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Products')
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final products =
                  snapshot.data!.docs;

              return SingleChildScrollView(
                child: DataTable(
                  columns: const [

  DataColumn(
    label: Text("Image"),
  ),

  DataColumn(
    label: Text("Name"),
  ),

  DataColumn(
    label: Text("Category"),
  ),

  DataColumn(
    label: Text("Price"),
  ),

  DataColumn(
    label: Text("Actions"),
  ),
],
                  rows: products.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    return DataRow(
                      cells: [

                       DataCell(
  SizedBox(
    width: 60,
    height: 60,
    child: ClipRRect(
      borderRadius:
          BorderRadius.circular(8),
      child: Image.network(
        data["images"] != null &&
                data["images"].length > 0
            ? data["images"][0]
            : "",
        fit: BoxFit.cover,
        errorBuilder:
            (_, __, ___) =>
                const Icon(Icons.image),
      ),
    ),
  ),
),

                        DataCell(
                          Text(
                            data["name"] ?? "",
                          ),
                        ),

DataCell(
  Text(
    data["category"] ?? "",
  ),
),

                        DataCell(
                          Text(
                            "${data["price"] ?? 0} EGP",
                          ),
                        ),

                        DataCell(
                          Row(
                            children: [

                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color:
                                      Colors.blue,
                                ),
                                onPressed: () {},
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red,
                                ),
                                onPressed: () async {
  await FirebaseFirestore.instance
      .collection('Products')
      .doc(doc.id)
      .delete();

  await loadDashboardData();
},
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

void showAddProductDialog(BuildContext context) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final deliveryController = TextEditingController();
  final categoryController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xff111827),

        title: const Text(
          "Add Product",
          style: TextStyle(color: Colors.white),
        ),

        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// NAME
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Product Name",
                  ),
                ),

                const SizedBox(height: 15),

                /// DESCRIPTION
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                  ),
                ),

                const SizedBox(height: 15),

                /// PRICE
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Price",
                  ),
                ),

                const SizedBox(height: 15),

                /// DELIVERY TEXT
                TextField(
                  controller: deliveryController,
                  decoration: const InputDecoration(
                    labelText: "Delivery Text",
                  ),
                ),

                const SizedBox(height: 15),

TextField(
  controller: categoryController,
  decoration: const InputDecoration(
    labelText: "Category",
  ),
),

const SizedBox(height: 15),

ElevatedButton.icon(
  icon: const Icon(Icons.image),
  label: const Text("Choose Image"),
  onPressed: () async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      selectedImage = result.files.first.bytes;

      setState(() {});
    }
  },
),

if (selectedImage != null)
  const Padding(
    padding: EdgeInsets.only(top: 10),
    child: Text(
      "Image Selected ✅",
    ),
  ),
              ],
            ),
          ),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save"),

            onPressed: () async {

  if (selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Choose an image first"),
      ),
    );
    return;
  }

  await uploadToCloudinary();

              await FirebaseFirestore.instance
                  .collection("Products")
                  .add({

                "id": DateTime.now()
    .millisecondsSinceEpoch
    .toString(),

                "name": nameController.text.trim(),

                "description":
                    descriptionController.text.trim(),

                "price": double.tryParse(
      priceController.text.trim(),
    ) ??
    0,

                "deliveryText":
                    deliveryController.text.trim(),

                "category": categoryController.text.trim(),

                "images": [
  uploadedImageUrl,
],

                "createdAt":
                    FieldValue.serverTimestamp(),
              });



              await loadDashboardData();


              if (mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Product Added Successfully ✅",
                    ),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

Widget buildOrdersPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Orders",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("orders")
                .orderBy(
                  "orderedAt",
                  descending: true,
                )
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final orders =
                  snapshot.data!.docs;

              return SingleChildScrollView(
                child: DataTable(
                  columns: const [

                    DataColumn(
                      label: Text("Image"),
                    ),

                    DataColumn(
                      label: Text("Customer"),
                    ),

                    DataColumn(
                      label: Text("Phone"),
                    ),

                    DataColumn(
                      label: Text("Total"),
                    ),

                    DataColumn(
                      label: Text("Status"),
                    ),

                    DataColumn(
                      label: Text("Action"),
                    ),
                  ],

                  rows: orders.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    final items =
                        data["items"] ?? [];

                    String image = "";

                    if (items.isNotEmpty) {
                      image =
                          items[0]["image"] ?? "";
                    }

                    return DataRow(
                      cells: [

                        DataCell(
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(
                                Icons.image,
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            data["name"] ?? "",
                          ),
                        ),

                        DataCell(
                          Text(
                            data["phone"] ?? "",
                          ),
                        ),

                        DataCell(
                          Text(
                            "${data["total"] ?? 0} EGP",
                          ),
                        ),

                        DataCell(
  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: data["status"] == "delivered"
          ? Colors.green
          : data["status"] == "processing"
              ? Colors.orange
              : data["status"] == "cancelled"
                  ? Colors.red
                  : Colors.blue,
      borderRadius:
          BorderRadius.circular(20),
    ),
    child: Text(
      data["status"] ?? "",
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),

                        DataCell(
  Row(
    children: [

      IconButton(
        icon: const Icon(
          Icons.visibility,
          color: Colors.lightBlueAccent,
        ),
        onPressed: () {

          final order = {
            ...data,
            "docId": doc.id,
          };

          showOrderDetails(order);
        },
      ),

      PopupMenuButton<String>(
        onSelected: (value) async {

          await FirebaseFirestore.instance
              .collection("orders")
              .doc(doc.id)
              .update({
            "status": value,
          });
        },

        itemBuilder: (context) => [

          const PopupMenuItem(
            value: "pending",
            child: Text("Pending"),
          ),

          const PopupMenuItem(
            value: "processing",
            child: Text("Processing"),
          ),

          const PopupMenuItem(
            value: "shipped",
            child: Text("Shipped"),
          ),

          const PopupMenuItem(
            value: "delivered",
            child: Text("Delivered"),
          ),

          const PopupMenuItem(
            value: "cancelled",
            child: Text("Cancelled"),
          ),
        ],
      ),
    ],
  ),
),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildUsersPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Users",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final users = snapshot.data!.docs;

              return SingleChildScrollView(
                child: DataTable(
                  columns: const [

                    DataColumn(
                      label: Text("Name"),
                    ),

                    DataColumn(
                      label: Text("Email"),
                    ),

                    DataColumn(
                      label: Text("Phone"),
                    ),

                    DataColumn(
                      label: Text("Role"),
                    ),

                    DataColumn(
                      label: Text("Action"),
                    ),
                  ],

                  rows: users.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    return DataRow(
                      cells: [

                        DataCell(
                          Text(
                            data["name"] ?? "",
                          ),
                        ),

                        DataCell(
                          Text(
                            data["email"] ?? "",
                          ),
                        ),

                        DataCell(
                          Text(
                            data["phone"] ?? "",
                          ),
                        ),

                        DataCell(
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  data["role"] == "admin"
                                      ? Colors.red
                                      : Colors.blue,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              data["role"] ?? "user",
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        DataCell(
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () async {

                              await FirebaseFirestore
                                  .instance
                                  .collection(
                                      "users")
                                  .doc(doc.id)
                                  .delete();

                              await loadDashboardData();
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildCouponsPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            const Text(
              "Coupons",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                showAddCouponDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Coupon"),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("promoCodes")
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final coupons =
                  snapshot.data!.docs;

              return SingleChildScrollView(
                child: DataTable(
                  columns: const [

                    DataColumn(
                      label: Text("Code"),
                    ),

                    DataColumn(
                      label: Text("Discount"),
                    ),

                    DataColumn(
                      label: Text("Status"),
                    ),

                    DataColumn(
                      label: Text("Expire"),
                    ),

                    DataColumn(
                      label: Text("Action"),
                    ),
                  ],

                  rows: coupons.map((doc) {

                    final data =
                        doc.data()
                            as Map<String, dynamic>;

                    return DataRow(
                      cells: [

                        DataCell(
                          Text(doc.id),
                        ),

                        DataCell(
                          Text(
                            "${data["discount"]}%"
                          ),
                        ),

                        DataCell(
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  data["active"] == true
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              data["active"] == true
                                  ? "Active"
                                  : "Disabled",
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            data["expireAt"] != null
                                ? (data["expireAt"]
                                        as Timestamp)
                                    .toDate()
                                    .toString()
                                    .split(" ")
                                    .first
                                : "-",
                          ),
                        ),

                        DataCell(
                          Row(
                            children: [

                              IconButton(
                                icon: Icon(
                                  data["active"] == true
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  color: Colors.orange,
                                ),
                                onPressed: () async {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          "promoCodes")
                                      .doc(doc.id)
                                      .update({
                                    "active":
                                        !(data["active"] ??
                                            false),
                                  });
                                },
                              ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          "promoCodes")
                                      .doc(doc.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget menuItem(
  IconData icon,
  String title,
  int index,
) {
  bool selected = selectedIndex == index;

  return ListTile(
    leading: Icon(
      icon,
      color: selected
          ? Colors.lightBlueAccent
          : Colors.white,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: selected
            ? Colors.lightBlueAccent
            : Colors.white,
      ),
    ),
    onTap: () {
      setState(() {
        selectedIndex = index;
      });
    },
  );
}

void showOrderDetails(Map<String, dynamic> order) {
  final items = order["items"] ?? [];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xff111827),
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(
                  "Customer: ${order["name"] ?? ""}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Phone: ${order["phone"] ?? ""}",
                ),

                const SizedBox(height: 10),

                Text(
                  "Status: ${order["status"] ?? ""}",
                ),

                const SizedBox(height: 10),

                Text(
                  "Total: ${order["total"] ?? 0} EGP",
                ),

                const Divider(height: 30),

                const Text(
                  "Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                ...items.map<Widget>((item) {
                  return Card(
                    color: Colors.black26,
                    child: ListTile(
                      leading: Image.network(
                        item["image"] ?? "",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(
                                  Icons.image,
                                ),
                      ),
                      title: Text(
                        item["name"] ?? "",
                      ),
                      subtitle: Text(
                        "Qty: ${item["quantity"] ?? 1} | Size: ${item["size"] ?? "-"}",
                      ),
                      trailing: Text(
                        "${item["price"] ?? 0} EGP",
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        actions: [

          ElevatedButton(
            onPressed: () async {

              await FirebaseFirestore.instance
                  .collection("orders")
                  .doc(order["docId"])
                  .update({
                "status": "processing",
              });

              Navigator.pop(context);
            },
            child: const Text(
              "Processing",
            ),
          ),

          ElevatedButton(
            onPressed: () async {

              await FirebaseFirestore.instance
                  .collection("orders")
                  .doc(order["docId"])
                  .update({
                "status": "delivered",
                "deliveredAt":
                    FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
            },
            child: const Text(
              "Delivered",
            ),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

void showAddCouponDialog() {

  final codeController =
      TextEditingController();

  final discountController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (context) {

      return AlertDialog(
        backgroundColor:
            const Color(0xff111827),

        title: const Text(
          "Add Coupon",
        ),

        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: codeController,
                decoration:
                    const InputDecoration(
                  labelText: "Coupon Code",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    discountController,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText: "Discount %",
                ),
              ),
            ],
          ),
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {

              await FirebaseFirestore
                  .instance
                  .collection("promoCodes")
                  .doc(
                    codeController.text
                        .trim()
                        .toUpperCase(),
                  )
                  .set({

                "discount":
                    int.parse(
                      discountController.text,
                    ),

                "active": true,

                "expireAt":
                    Timestamp.fromDate(
                  DateTime(
                    2026,
                    12,
                    31,
                  ),
                ),
              });

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

  Widget dashboardCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xff111827),
          borderRadius: BorderRadius.circular(
            20,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Icon(
              icon,
              size: 35,
            ),

            const Spacer(),

            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(title),
          ],
        ),
      ),
    );
  }
}