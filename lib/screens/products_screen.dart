import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'banner_slider_screen.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'admin_orders_screen.dart';
import 'add_edit_products_screen.dart';
import 'custom_drawer_screen.dart';
import 'product_details_screen.dart';
import 'profile_screen.dart';
import 'sales_screen.dart';

///////////////////// 🛍 PRODUCTS /////////////////////

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> favourites = [];

  int currentIndex = 0;

 int salesCount = 0;
 bool isAdmin = false;

 bool salesSeen = false;

@override
void initState() {
  super.initState();

  FirebaseMessaging.instance.requestPermission();

  loadFavourites();
  loadCart();

  checkAdmin();
  loadSalesCount();
}

Future<void> checkAdmin() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (doc.exists &&
    (doc.data()?['role'] ?? '') == 'admin') {
    setState(() {
      isAdmin = true;
    });
  }
}

Future<void> loadSalesCount() async {
  var snapshot = await FirebaseFirestore.instance
      .collection('sales')
      .get();

  setState(() {
    salesCount = snapshot.docs.length;
  });
}

Future<void> toggleFavourite(Map<String, dynamic> item) async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var favRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites');

  var existing = await favRef
      .where("name", isEqualTo: item['name'])
      .get();

  if (existing.docs.isNotEmpty) {
    // ❌ remove
    await favRef.doc(existing.docs.first.id).delete();

    if (!mounted) return;

    setState(() {
      favourites.removeWhere((e) => e['name'] == item['name']);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Removed from Favourites ❌")),
    );
  } else {
    // ❤️ add
    await favRef.add(item);

    if (!mounted) return;

    setState(() {
      favourites.add(item);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added To Favourite ❤️")),
    );
  }
}

Future<void> loadFavourites() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites')
      .get();

 setState(() {
  favourites = snapshot.docs.map((doc) {
    var data = doc.data();
    data['docId'] = doc.id; // 🔥 مهم جدًا
    return data;
  }).toList();
});
}

Future<void> removeFromFavourites(int index) async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var favRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favourites');

  var docId = favourites[index]['docId'];

  if (docId != null) {
    await favRef.doc(docId).delete();
  }

  setState(() {
    favourites.removeAt(index);
  });
}

Future<void> loadCart() async {
  var user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  var snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .get();

  setState(() {
    cart = snapshot.docs.map((doc) => doc.data()).toList();
  });
}

Widget buildProducts() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance.collection('Products')
.orderBy('createdAt', descending: true)
.snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      var products = snapshot.data!.docs;

return Column(
  children: [

    /// 🔥 البانر فوق
    BannerSlider(isAdmin: isAdmin),

/// 🔥 OUR PRODUCTS
Padding(
  padding: const EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 20,
  ),

  child: Builder(
    builder: (context) {

      final bool isDark =
          Theme.of(context).brightness ==
              Brightness.dark;

      final Color textColor =
          isDark
              ? Colors.white
              : const Color(0xFF1D1B20);

      final Color lineColor =
          isDark
              ? const Color(0xFF6EA6C1)
              : const Color(0xFF5B8DA8);

      return Row(
        children: [

          /// LEFT LINE
          Expanded(
            child: Container(
              height: 2,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    lineColor.withValues(alpha: .9),
                  ],

                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          /// TEXT
          Text(
            "Our Products",

            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(width: 14),

          /// RIGHT LINE
          Expanded(
            child: Container(
              height: 2,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: .9),
                    Colors.transparent,
                  ],

                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
),

    /// 🔥 المنتجات تحت
    Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio:
    MediaQuery.of(context).size.width < 400
        ? 0.54
        : 0.60,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          var product = products[index];
          var data = product.data();

          List<String> images =
    data.containsKey('images')
        ? List<String>.from(data['images'])
        : [data['image'] ?? ""];

          bool isFav =
              favourites.any((e) => e['name'] == data['name']);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(
                    product: product,
                    cart: cart,

                    onAddToCart: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),

    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF111827),
        Color(0xFF0B1220),
        Color(0xFF091428),
      ],
    ),

    border: Border.all(
      color: Color(0xFF1F2A44),
      width: 1,
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .35),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),

  child: Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      /// 🔥 IMAGE
      AspectRatio(
  aspectRatio: 0.8,
        child: Stack(
          children: [

            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),

              child: Image.network(
                images.isNotEmpty ? images[0] : "",
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

            /// ❤️ Favourite
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: () {

                  var item = {
                    "name": data['name'],
                    "price": data['price'],
                    "image": images.isNotEmpty
                        ? images[0]
                        : "",
                  };

                  toggleFavourite(item);
                },

                child: Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .45),
                    border: Border.all(
                      color: Colors.white10,
                    ),
                  ),

                  child: Icon(
                    isFav
                        ? Icons.favorite
                        : Icons.favorite_border,

                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            /// 🔥 NEW BADGE
            if (data['createdAt'] != null &&
                DateTime.now()
                        .difference(
                          (data['createdAt'] as Timestamp)
                              .toDate(),
                        )
                        .inDays <
                    7)

              Positioned(
                left: 12,
                bottom: 12,

                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Color(0xFF6EA6C1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),

                  child: Text(
                    "NEW",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            /// 🔥 MENU BUTTON
            if (isAdmin)
              Positioned(
                top: 12,
                right: 12,

                child: PopupMenuButton<String>(
                  color: Color(0xFF111827),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),

                  onSelected: (value) async {

                    if (value == "edit") {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditProductScreen(
                            docId: product.id,
                            oldData: data,
                          ),
                        ),
                      );
                    }

                    if (value == "delete") {

                      await FirebaseFirestore.instance
                          .collection('Products')
                          .doc(product.id)
                          .delete();
                    }
                  },

                  itemBuilder: (context) => [

                    PopupMenuItem(
                      value: "edit",

                      child: Row(
                        children: [

                          Icon(
                            Icons.edit,
                            color: Color(0xFF6EA6C1),
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: "delete",

                      child: Row(
                        children: [

                          Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),

                          SizedBox(width: 10),

                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  child: Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .45),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      /// 🔥 NAME + PRICE
        Padding(
          padding: const EdgeInsets.only(
            top: 18,
            left: 8,
            right: 8,
            bottom: 8,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              Text(
  data['name'],
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,

  style: TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),

              SizedBox(height: 0.4),

              Text(
                "${data['price']} EGP",

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

Spacer(),

      /// 🔥 ADD TO CART BUTTON
      Padding(
        padding: const EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 5,
          top: 1,
        ),

        child: InkWell(
          borderRadius: BorderRadius.circular(20),

          onTap: () {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        product: product,
        cart: cart,
        onAddToCart: () {
          setState(() {});
        },
      ),
    ),
  );

},

          child: Container(
            width: double.infinity,
            height: 40,

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),

              color: Colors.white.withValues(alpha: .06),

              border: Border.all(
                color: Colors.white10,
              ),
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF6EA6C1),
                ),

                SizedBox(width: 5),

                Text(
                  "Add to Cart",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
)
              ],
            ),
          );
        },
      ),
    ),
  ],
);
    },
  );
}

Widget buildFavourites() {
  if (favourites.isEmpty) {
    return Center(
      child: Text(
        "No Favourites Yet ❤️",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [

        /// HEADER fav
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white10),
            gradient: LinearGradient(
              colors: [
                Color(0xFF0E1220),
                Color(0xFF151A29),
              ],
            ),
          ),
          child: Row(
            children: [

              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1B2233),
                  border: Border.all(
                    color: Color(0xFF6EA6C1),
                  ),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Color(0xFF6EA6C1),
                  size: 30,
                ),
              ),

              SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      "My Favourites",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "${favourites.length} items saved",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      "Items you love, all in one place.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 25),

        /// GRID
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: favourites.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio:
    MediaQuery.of(context).size.width < 400
        ? 0.54
        : 0.60,
crossAxisSpacing: 10,
mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {

            var item = favourites[index];

            return buildFavouriteCard(
              item,
              index,
            );
          },
        ),

        SizedBox(height: 25),

        /// FEATURES
        Container(
          padding: EdgeInsets.symmetric(
            vertical: 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [

              buildFeature(
                Icons.workspace_premium_outlined,
                "Premium Quality",
                "Comfort & quality",
              ),

              buildFeature(
                Icons.assignment_return_outlined,
                "Easy Returns",
                "14-day return",
              ),

              buildFeature(
                Icons.headset_mic_outlined,
                "Support",
                "24/7 Help",
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildFavouriteCard(
  Map<String,dynamic> item,
  int index,
) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF111827),
          Color(0xFF0B1220),
          Color(0xFF091428),
        ],
      ),
      border: Border.all(
        color: Color(0xFF1F2A44),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .35),
          blurRadius: 20,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        /// IMAGE
        AspectRatio(
          aspectRatio: 0.8,
          child: Stack(
            children: [

              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Image.network(
                  item["image"],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),

              /// ❤️ REMOVE FROM FAVOURITES
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    removeFromFavourites(index);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .45),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// NAME + PRICE
        Padding(
          padding: const EdgeInsets.only(
            top: 15,
            left: 8,
            right: 8,
            bottom: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                item["name"],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 4),

              Text(
                "${item["price"]} EGP",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6EA6C1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        Spacer(),

        /// ADD TO CART BUTTON
        Padding(
          padding: const EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: 2,
            top: 0,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              /// add to cart
            },
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF6EA6C1),
                  ),

                  SizedBox(width: 5),

                  Text(
                    "Add to Cart",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildFeature(
  IconData icon,
  String title,
  String subtitle,
) {
  return Expanded(
    child: Column(
      children: [

        CircleAvatar(
          radius: 28,
          backgroundColor:
              Color(0xFF1A2233),
          child: Icon(
            icon,
            color: Color(0xFF6EA6C1),
          ),
        ),

        SizedBox(height: 10),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 4),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Widget buildBadge({
  required IconData icon,
  required int count,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Icon(icon, size: 28),

      if (count > 0)
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {



int favCount = favourites.length;
    
return Scaffold(
  appBar: AppBar(
  centerTitle: false,
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  iconTheme: IconThemeData(
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black,
  ),
  title: currentIndex == 0

    /// 🔥 MEDLIFE LOGO
    ? RichText(
        text: TextSpan(
          children: [

            TextSpan(
              text: "Med",

              style: GoogleFonts.poppins(
                color: Color(0xFF35C2F1),
                fontSize: 21,
                fontWeight: FontWeight.w900,

                letterSpacing: 0.5,

                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),

            TextSpan(
              text: "Life",

              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w900,

                letterSpacing: 0.5,

                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      )

    /// 🔥 باقي الصفحات
    : Text(
        currentIndex == 1
            ? "Cart"
            : currentIndex == 2
                ? "Favourites"
                : "My Orders",

        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
  actions: [
    /* Padding(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: GestureDetector(
    onTap: () {
      MyApp.of(context)!.toggleTheme();
    },
    child: AnimatedContainer(
      duration: Duration(milliseconds: 250),
      width: 50,
      height: 25,
      padding: EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        // 🔥 الخلفية الرمادي الثابتة
        color: Colors.grey.shade400,

        border: Border.all(
          color: Colors.grey.shade500,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MyApp.of(context)!.isDark
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              // 🔥 لون الدائرة نفسها
              color: MyApp.of(context)!.isDark
                  ? Colors.black
                  : Colors.white,

              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Icon(
              MyApp.of(context)!.isDark
                  ? Icons.nightlight_round
                  : Icons.wb_sunny,
              size: 15,
              color: MyApp.of(context)!.isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
      ),
    ),
  ),
),
*/

/// 🔥 SALES
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 4),
  child: GestureDetector(
    onTap: () async {

      /// 👁️ المستخدم شاف العروض
      setState(() {
        salesSeen = true;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalesScreen(
            isAdmin: isAdmin,
          ),
        ),
      );
    },

    child: Stack(
      clipBehavior: Clip.none,
      children: [

        /// 🔥 ICON
       Container(
  padding: EdgeInsets.all(8),
  child: Icon(
    Icons.percent,
    color:
        Theme.of(context).brightness ==
                Brightness.dark
            ? Colors.white
            : Colors.black,
    size: 28,
  ),
),

        /// 🔴 BADGE
        if (!salesSeen && salesCount > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                salesCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  ),
),

if (isAdmin)
  IconButton(
    icon: Icon(Icons.insert_chart_outlined_rounded),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminOrdersScreen()),
      );
    },
  ),
  // 👤 Profile
  IconButton(
    icon: Icon(Icons.person),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    },
  ),
IconButton(
  icon: Icon(Icons.menu),
  onPressed: () {
    showGeneralDialog(
      context: context,
      barrierLabel: "Menu",
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 500), // 🔥 أسرع + Bounce
      pageBuilder: (_, _, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: const CustomDrawerScreen(),
        );
      },
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack, // 🔥 Bounce effect
        );

        return SlideTransition(
          position: Tween(
            begin: Offset(1, 0),
            end: Offset(0, 0),
          ).animate(curved),
          child: child,
        );
      },
    );
  },
),
],
  ),

 body: currentIndex == 0
    ? buildProducts()
    : currentIndex == 1
        ? CartScreen(cart: cart)
        : currentIndex == 2
            ? buildFavourites()
            : MyOrdersScreen(),

floatingActionButton: isAdmin
    ? Container(
        width: 50,
        height: 50,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF59C7FF),
              Color(0xFF6EA6C1),
            ],
          ),
        ),

        child: FloatingActionButton(
          heroTag: "addProduct",

          elevation: 0,

          backgroundColor: Colors.transparent,

          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditProductScreen(),
              ),
            );
          },

          child: const Icon(
            Icons.add,
            size: 25,
            color: Colors.white,
          ),
        ),
      )
    : null,

    floatingActionButtonLocation:
    FloatingActionButtonLocation.endFloat,

bottomNavigationBar: Container(
  margin: const EdgeInsets.only(
    left: 4,
    right: 4,
  ),

  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),

    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF111827),
        Color(0xFF0B1220),
        Color(0xFF091428),
      ],
    ),

    border: Border.all(
      color: Colors.white10,
      width: 1,
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .35),
        blurRadius: 25,
        spreadRadius: 2,
        offset: const Offset(0, 10),
      ),
    ],
  ),

  child: ClipRRect(
    borderRadius: BorderRadius.circular(30),

    child: BottomNavigationBar(
      currentIndex: currentIndex,

      backgroundColor: Colors.transparent,

      elevation: 0,

      type: BottomNavigationBarType.fixed,

      selectedItemColor: Colors.white,

      unselectedItemColor: Colors.white70,

      showUnselectedLabels: true,

      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),

      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),

      onTap: (i) {
        setState(() {
          currentIndex = i;
        });
      },

      items: [

        /// 🏬 PRODUCTS
        BottomNavigationBarItem(
          label: "Products",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 0 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 0
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 0
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withValues(alpha: .35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: Icon(
              Icons.store,
              color: currentIndex == 0
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
        ),

        /// 🛒 CART
        BottomNavigationBarItem(
          label: "Cart",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 1 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 1
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 1
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withValues(alpha: .35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),

              builder: (context, snapshot) {

                int count =
                    snapshot.data?.docs.length ?? 0;

                return buildBadge(
                  icon: Icons.shopping_cart,
                  count: count,
                );
              },
            ),
          ),
        ),

        /// ❤️ FAVOURITES
        BottomNavigationBarItem(
          label: "Favourites",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 2 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 2
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 2
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withValues(alpha: .35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: buildBadge(
              icon: Icons.favorite,
              count: favCount,
            ),
          ),
        ),

        /// 📦 ORDERS
        BottomNavigationBarItem(
          label: "My Orders",

          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            padding: EdgeInsets.symmetric(
              horizontal: currentIndex == 3 ? 14 : 0,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),

              gradient: currentIndex == 3
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF59C7FF),
                        Color(0xFF6EA6C1),
                      ],
                    )
                  : null,

              boxShadow: currentIndex == 3
                  ? [
                      BoxShadow(
                        color: const Color(0xFF59C7FF)
                            .withValues(alpha: .35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [],
            ),

            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'userId',
                    isEqualTo:
                        FirebaseAuth.instance.currentUser?.uid,
                  )
                  .snapshots(),

              builder: (context, snapshot) {

                int count =
                    snapshot.data?.docs.length ?? 0;

                return buildBadge(
                  icon: Icons.shopping_bag,
                  count: count,
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
),
);
  }
}