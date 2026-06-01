import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

          /// CONTENT
          Expanded(
  child: selectedIndex == 0
      ? buildDashboard()
      : selectedIndex == 1
          ? buildProductsPage()
          : Center(
              child: Text(
                "Coming Soon",
                style: TextStyle(fontSize: 30),
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
      ],
    ),
  );
}

Widget buildProductsPage() {
  return const Center(
    child: Text(
      "Products Page",
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
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