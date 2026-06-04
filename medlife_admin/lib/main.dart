import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'admin_login.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      home: FirebaseAuth.instance.currentUser != null
    ? const DashboardScreen()
    : const AdminLogin(),
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

  int pendingOrders = 0;
int processingOrders = 0;
int deliveredOrders = 0;
int cancelledOrders = 0;

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

    double totalRevenue = 0;

for (var order in orders.docs) {
  final data =
      order.data() as Map<String, dynamic>;

  if (data["status"] == "delivered") {
    totalRevenue +=
        (data["total"] ?? 0).toDouble();
  }
}

int pending = 0;
int processing = 0;
int delivered = 0;
int cancelled = 0;

for (var order in orders.docs) {
  final data =
      order.data() as Map<String, dynamic>;

  switch (data["status"]) {
    case "pending":
      pending++;
      break;

    case "processing":
      processing++;
      break;

    case "delivered":
      delivered++;
      break;

    case "cancelled":
      cancelled++;
      break;
  }
}

setState(() {
  productsCount = products.docs.length;
  ordersCount = orders.docs.length;
  usersCount = users.docs.length;

  revenue = totalRevenue;

  pendingOrders = pending;
  processingOrders = processing;
  deliveredOrders = delivered;
  cancelledOrders = cancelled;
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
menuItem(Icons.image, "Banners", 6),
const Spacer(),
ListTile(
  leading: const Icon(
    Icons.logout,
    color: Colors.red,
  ),
  title: const Text(
    "Logout",
    style: TextStyle(
      color: Colors.red,
    ),
  ),
  onTap: () async {

    await FirebaseAuth.instance
        .signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => const AdminLogin(),
      ),
    );
  },
),
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
                      : selectedIndex == 5
                          ? buildOffersPage()
                          : selectedIndex == 6
                              ? buildBannersPage()
                              : const Center(
                                  child: Text(
                                    "Coming Soon",
                                    style: TextStyle(
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
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
        const SizedBox(height: 25),

Row(
  children: [

    dashboardCard(
      "Pending",
      pendingOrders.toString(),
      Icons.schedule,
    ),

    const SizedBox(width: 20),

    dashboardCard(
      "Processing",
      processingOrders.toString(),
      Icons.autorenew,
    ),

    const SizedBox(width: 20),

    dashboardCard(
      "Delivered",
      deliveredOrders.toString(),
      Icons.check_circle,
    ),

    const SizedBox(width: 20),

    dashboardCard(
      "Cancelled",
      cancelledOrders.toString(),
      Icons.cancel,
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
  label: Text("Stock"),
),

DataColumn(
  label: Text("Status"),
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
  Text(
    "${data["stock"] ?? 0}",
  ),
),
DataCell(
  Container(
    padding:
        const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color:
          (data["stock"] ?? 0) > 0
              ? Colors.green
              : Colors.red,
      borderRadius:
          BorderRadius.circular(20),
    ),
    child: Text(
      (data["stock"] ?? 0) > 0
          ? "In Stock"
          : "Out Of Stock",
    ),
  ),
),

                        DataCell(
                          Row(
                            children: [

                              IconButton(
  icon: const Icon(
    Icons.edit,
    color: Colors.blue,
  ),
  onPressed: () {
    showEditProductDialog(
      doc.id,
      data,
    );
  },
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
  final stockController = TextEditingController();

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

TextField(
  controller: stockController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: "Stock",
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

    "stock": int.tryParse(
      stockController.text.trim(),
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

void showEditProductDialog(
  String docId,
  Map<String, dynamic> product,
) {
  final nameController = TextEditingController(
    text: product["name"] ?? "",
  );

  final descriptionController =
      TextEditingController(
    text: product["description"] ?? "",
  );

  final priceController = TextEditingController(
    text: product["price"].toString(),
  );

  final categoryController =
      TextEditingController(
    text: product["category"] ?? "",
  );

  final stockController =
    TextEditingController(
  text:
      (product["stock"] ?? 0)
          .toString(),
);

  final deliveryController =
      TextEditingController(
    text: product["deliveryText"] ?? "",
  );

  Uint8List? newImage;

  String imageUrl =
      product["images"] != null &&
              product["images"].isNotEmpty
          ? product["images"][0]
          : "";

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                const Color(0xff111827),

            title: const Text(
              "Edit Product",
              style: TextStyle(
                color: Colors.white,
              ),
            ),

            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [

                    TextField(
                      controller:
                          nameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Product Name",
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          descriptionController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Description",
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          priceController,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Price",
                      ),
                    ),

                    TextField(
  controller: stockController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
    labelText: "Stock",
  ),
),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          categoryController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Category",
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    TextField(
                      controller:
                          deliveryController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            "Delivery Text",
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.image,
                      ),
                      label: const Text(
                        "Change Image",
                      ),
                      onPressed:
                          () async {

                        final result =
                            await FilePicker
                                .platform
                                .pickFiles(
                          type:
                              FileType.image,
                          withData:
                              true,
                        );

                        if (result !=
                            null) {
                          newImage =
                              result
                                  .files
                                  .first
                                  .bytes;

                          setDialogState(
                            () {},
                          );
                        }
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    if (newImage != null)
                      const Text(
                        "New Image Selected ✅",
                      ),

                    const SizedBox(
                      height: 15,
                    ),

                    if (imageUrl
                        .isNotEmpty)
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                        child:
                            Image.network(
                          imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  "Cancel",
                ),
              ),

              ElevatedButton(
                onPressed:
                    () async {

                  if (newImage !=
                      null) {

                    selectedImage =
                        newImage;

                    await uploadToCloudinary();

                    imageUrl =
                        uploadedImageUrl;
                  }

                  await FirebaseFirestore
                      .instance
                      .collection(
                        "Products",
                      )
                      .doc(docId)
                      .update({

                    "name":
                        nameController
                            .text
                            .trim(),

                    "description":
                        descriptionController
                            .text
                            .trim(),

                    "price":
                        double.tryParse(
                              priceController
                                  .text
                                  .trim(),
                            ) ??
                            0,

                    "category":
                        categoryController
                            .text
                            .trim(),

                    "stock": int.tryParse(
      stockController.text,
    ) ??
    0,

                    "deliveryText":
                        deliveryController
                            .text
                            .trim(),

                    "images": [
                      imageUrl,
                    ],
                  });

                  Navigator.pop(
                    dialogContext,
                  );

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Product Updated Successfully ✅",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Save",
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

void showAddBannerDialog() {
  Uint8List? bannerImage;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder:
            (context, setDialogState) {

          return AlertDialog(
            backgroundColor:
                const Color(
              0xff111827,
            ),

            title: const Text(
              "Add Banner",
            ),

            content: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.image,
                  ),
                  label: const Text(
                    "Choose Image",
                  ),
                  onPressed:
                      () async {

                    final result =
                        await FilePicker
                            .platform
                            .pickFiles(
                      type:
                          FileType.image,
                      withData:
                          true,
                    );

                    if (result !=
                        null) {

                      bannerImage =
                          result
                              .files
                              .first
                              .bytes;

                      setDialogState(
                        () {},
                      );
                    }
                  },
                ),

                const SizedBox(
                  height: 15,
                ),

                if (bannerImage !=
                    null)
                  const Text(
                    "Image Selected ✅",
                  ),
              ],
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  "Cancel",
                ),
              ),

              ElevatedButton(
                onPressed:
                    () async {

                  if (bannerImage ==
                      null) {
                    return;
                  }

                  selectedImage =
                      bannerImage;

                  await uploadToCloudinary();

                  await FirebaseFirestore
                      .instance
                      .collection(
                        "banners",
                      )
                      .add({

                    "image":
                        uploadedImageUrl,

                    "active": true,

                    "createdAt":
                        FieldValue
                            .serverTimestamp(),
                  });

                  Navigator.pop(
                    dialogContext,
                  );
                },
                child:
                    const Text("Save"),
              ),
            ],
          );
        },
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

Widget buildOffersPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [

            const Text(
              "Offers",
              style: TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                showAddOfferDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text(
                "Add Offer",
              ),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("offers")
                .orderBy(
                  "createdAt",
                  descending: true,
                )
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final offers =
                  snapshot.data!.docs;

              return DataTable(
                columns: const [

                  DataColumn(
                    label: Text("Title"),
                  ),

                  DataColumn(
                    label: Text("Discount"),
                  ),

                  DataColumn(
                    label: Text("Status"),
                  ),

                  DataColumn(
                    label: Text("Actions"),
                  ),
                ],

                rows: offers.map((doc) {

                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  return DataRow(
                    cells: [

                      DataCell(
                        Text(
                          data["title"] ?? "",
                        ),
                      ),

                      DataCell(
                        Text(
                          "${data["discount"]}%"
                        ),
                      ),

                      DataCell(
                        Switch(
                          value:
                              data["active"] ??
                                  true,
                          onChanged:
                              (value) async {

                            await FirebaseFirestore
                                .instance
                                .collection(
                                    "offers")
                                .doc(doc.id)
                                .update({
                              "active":
                                  value,
                            });
                          },
                        ),
                      ),

                      DataCell(
                        Row(
                          children: [

                            IconButton(
                              icon:
                                  const Icon(
                                Icons.edit,
                                color:
                                    Colors.blue,
                              ),
                              onPressed: () {
                                showEditOfferDialog(
                                  doc.id,
                                  data,
                                );
                              },
                            ),

                            IconButton(
                              icon:
                                  const Icon(
                                Icons.delete,
                                color:
                                    Colors.red,
                              ),
                              onPressed:
                                  () async {

                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                        "offers")
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
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildBannersPage() {
  return Padding(
    padding: const EdgeInsets.all(25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [

            const Text(
              "Banners",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            ElevatedButton.icon(
              onPressed: () {
                showAddBannerDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text("Add Banner"),
            ),
          ],
        ),

        const SizedBox(height: 25),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("banners")
                .snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              final banners =
                  snapshot.data!.docs;

              return GridView.builder(
                itemCount: banners.length,

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),

                itemBuilder: (context, index) {

                  final banner =
                      banners[index];

                  final data =
                      banner.data()
                          as Map<String, dynamic>;

                  return Container(
                    decoration: BoxDecoration(
                      color:
                          const Color(0xff111827),
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),

                    child: Column(
                      children: [

                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(
                              top: Radius.circular(
                                15,
                              ),
                            ),
                            child: Image.network(
                              data["image"] ?? "",
                              width:
                                  double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.all(
                            10,
                          ),

                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [

                              Switch(
                                value:
                                    data["active"] ??
                                        true,
                                onChanged:
                                    (value) async {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          "banners")
                                      .doc(
                                          banner.id)
                                      .update({
                                    "active":
                                        value,
                                  });
                                },
                              ),

                              IconButton(
                                icon:
                                    const Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red,
                                ),
                                onPressed:
                                    () async {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          "banners")
                                      .doc(
                                          banner.id)
                                      .delete();
                                },
                              ),
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
        ),
      ],
    ),
  );
}

void showAddOfferDialog() {

  final titleController =
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
          "Add Offer",
        ),

        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            TextField(
              controller:
                  titleController,
              decoration:
                  const InputDecoration(
                labelText:
                    "Offer Title",
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            TextField(
              controller:
                  discountController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText:
                    "Discount %",
              ),
            ),
          ],
        ),

        actions: [

          ElevatedButton(
            onPressed: () async {

              await FirebaseFirestore
                  .instance
                  .collection("offers")
                  .add({

                "title":
                    titleController.text,

                "discount":
                    int.tryParse(
                          discountController
                              .text,
                        ) ??
                        0,

                "active": true,

                "createdAt":
                    FieldValue
                        .serverTimestamp(),
              });

              Navigator.pop(
                context,
              );
            },
            child:
                const Text("Save"),
          ),
        ],
      );
    },
  );
}

void showEditOfferDialog(
  String docId,
  Map<String, dynamic> offer,
) {

  final titleController =
      TextEditingController(
    text: offer["title"],
  );

  final discountController =
      TextEditingController(
    text:
        offer["discount"]
            .toString(),
  );

  showDialog(
    context: context,
    builder: (context) {

      return AlertDialog(
        backgroundColor:
            const Color(0xff111827),

        title: const Text(
          "Edit Offer",
        ),

        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            TextField(
              controller:
                  titleController,
            ),

            const SizedBox(
              height: 15,
            ),

            TextField(
              controller:
                  discountController,
              keyboardType:
                  TextInputType.number,
            ),
          ],
        ),

        actions: [

          ElevatedButton(
            onPressed: () async {

              await FirebaseFirestore
                  .instance
                  .collection("offers")
                  .doc(docId)
                  .update({

                "title":
                    titleController.text,

                "discount":
                    int.tryParse(
                          discountController
                              .text,
                        ) ??
                        0,
              });

              Navigator.pop(
                context,
              );
            },
            child:
                const Text("Save"),
          ),
        ],
      );
    },
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