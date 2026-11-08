import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  final List<Map<String, dynamic>> cart;
  final VoidCallback onAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.cart,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState
    extends State<ProductDetailsScreen> {
  String selectedSize = "M";
  int quantity = 1;
  int currentIndex = 0;

  bool isDescriptionOpen = true;
bool isDeliveryOpen = true;
bool isReviewsOpen = false;

@override
void initState() {
  super.initState();
}

  Widget buildSizeButton(String size) {
    bool isSelected = selectedSize == size;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },

      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),

        width: 64,
        height: 64,

        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: const Color(0xFF141118),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: isSelected
                ? const Color(0xFF4EA5FF)
                : Colors.white10,
            width: 1.6,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4EA5FF)
                        .withValues(alpha: .35),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),

        child: Text(
          size,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var product = widget.product;

    var data =
        widget.product.data() as Map<String, dynamic>;

    List images = data.containsKey('images')
        ? data['images']
        : [data['image']];

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        title: Text(
          product['name'] ?? "",
          style: TextStyle(color: Colors.white),
        ),

        iconTheme: IconThemeData(color: Colors.white),

        actions: [
          GestureDetector(

  onTap: () {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: widget.cart,
        ),
      ),
    );
  },

  child: Stack(
    clipBehavior: Clip.none,

    children: [

      Icon(
        Icons.shopping_cart_outlined,
        color: Colors.white,
        size: 30,
      ),

      if (widget.cart.isNotEmpty)

        Positioned(
          right: -6,
          top: -6,

          child: Container(

            padding: EdgeInsets.all(5),

            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),

            child: Text(

              "${widget.cart.length}",

              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
),

          SizedBox(width: 16),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [

            /// 🔥 BODY
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),

                child: Column(
                  children: [

                    /// 🔥 IMAGE + DETAILS
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        /// 🔥 IMAGE
                        Expanded(
                          flex: 5,

                          child: Column(
                            children: [

                              Container(
                                height: 520,

                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(
                                          28),
                                ),

                                clipBehavior: Clip.antiAlias,

                                child: Stack(
                                  children: [

                                    PageView.builder(
                                      itemCount:
                                          images.length,

                                      onPageChanged:
                                          (index) {
                                        setState(() {
                                          currentIndex =
                                              index;
                                        });
                                      },

                                      itemBuilder:
                                          (context,
                                              index) {
                                        return Image.network(
                                          images[index],
                                          fit: BoxFit.cover,
                                          width:
                                              double.infinity,
                                        );
                                      },
                                    ),

                                    GestureDetector(

  onTap: () {

    showDialog(

      context: context,

      builder: (_) {

        return Dialog(

          backgroundColor: Colors.black,

          insetPadding: EdgeInsets.zero,

          child: Stack(

            children: [

              InteractiveViewer(

                minScale: 1,
                maxScale: 5,

                child: Image.network(

                  images[currentIndex],

                  width: double.infinity,

                  height: double.infinity,

                  fit: BoxFit.contain,
                ),
              ),

              Positioned(

                top: 40,
                right: 20,

                child: GestureDetector(

                  onTap: () {
                    Navigator.pop(context);
                  },

                  child: Container(

                    padding: EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  },

  child: Container(

    padding: EdgeInsets.all(18),

    decoration: BoxDecoration(

      color: Colors.black45,
      shape: BoxShape.circle,
    ),

    child: Icon(

      Icons.zoom_in,

      color: Colors.white,
      size: 34,
    ),
  ),
)
                                  ],
                                ),
                              ),

                              SizedBox(height: 14),

                              /// 🔥 INDICATORS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,

                                children: List.generate(
                                  images.length,
                                  (index) {
                                    return AnimatedContainer(
                                      duration: Duration(
                                          milliseconds:
                                              250),

                                      margin:
                                          EdgeInsets
                                              .symmetric(
                                        horizontal: 4,
                                      ),

                                      width:
                                          currentIndex ==
                                                  index
                                              ? 24
                                              : 8,

                                      height: 8,

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            currentIndex ==
                                                    index
                                                ? const Color(
                                                    0xFF4EA5FF)
                                                : Colors
                                                    .white30,

                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 18),

                        /// 🔥 RIGHT SIDE
                        Expanded(
                          flex: 4,

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              SizedBox(height: 25),

                              Text(
                                product['name'],

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text(
                                "${product['price']} EGP",

                                style: TextStyle(
                                  color: const Color(
                                      0xFF4EA5FF),

                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 48),

                              /// 🔥 SIZE TITLE
                              Row(
  children: [

    Expanded(
      child: Text(
        "Choose Size",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    Icon(
      Icons.straighten,
      color: Color(0xFF4DA3FF),
      size: 18,
    ),

    SizedBox(width: 4),

    Flexible(
      child: Text(
        "Size Guide",
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFF4DA3FF),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
),

                              SizedBox(height: 22),

                              /// 🔥 SIZES
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,

                                children: [
                                  buildSizeButton("S"),
                                  buildSizeButton("M"),
                                  buildSizeButton("L"),
                                  buildSizeButton("XL"),
                                ],
                              ),

                              SizedBox(height: 55),

                              /// 🔥 QUANTITY
                              Text(
                                "Quantity",

                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),

                              SizedBox(height: 18),

                              Container(
                                width: 220,
                                height: 70,

                                decoration: BoxDecoration(
                                  color:
                                      const Color(
                                          0xFF141118),

                                  borderRadius:
                                      BorderRadius
                                          .circular(24),

                                  border: Border.all(
                                    color:
                                        Colors.white10,
                                  ),
                                ),

                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceEvenly,

                                  children: [

                                    IconButton(
                                      onPressed: () {
                                        if (quantity >
                                            1) {
                                          setState(() {
                                            quantity--;
                                          });
                                        }
                                      },

                                      icon: Icon(
                                        Icons.remove,
                                        color:
                                            Colors.white,
                                        size: 30,
                                      ),
                                    ),

                                    Text(
                                      "$quantity",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize: 26,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),

                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          quantity++;
                                        });
                                      },

                                      icon: Icon(
                                        Icons.add,
                                        color:
                                            Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 26),

                    /// 🔥 DESCRIPTION
Container(
  width: double.infinity,
  padding: EdgeInsets.all(22),

  decoration: BoxDecoration(
    color: const Color(0xFF141118),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white10,
    ),
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      /// HEADER
      GestureDetector(

        onTap: () {
          setState(() {
            isDescriptionOpen =
                !isDescriptionOpen;
          });
        },

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Text(
              "Description",

              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            AnimatedRotation(
              turns:
                  isDescriptionOpen
                      ? 0
                      : 0.5,

              duration:
                  Duration(milliseconds: 250),

              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      /// CONTENT
      AnimatedCrossFade(

        duration:
            Duration(milliseconds: 250),

        crossFadeState:
            isDescriptionOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,

        firstChild: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            SizedBox(height: 18),

            Text(
              data['description'] ??
                  "No description available",

              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),

        secondChild:
            SizedBox.shrink(),
      ),
    ],
  ),
),

                    SizedBox(height: 18),

                    /// 🔥 DELIVERY
Container(
  width: double.infinity,

  padding: EdgeInsets.all(22),

  decoration: BoxDecoration(
    color: const Color(0xFF141118),

    borderRadius:
        BorderRadius.circular(24),

    border: Border.all(
      color: Colors.white10,
    ),
  ),

  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      /// HEADER
      GestureDetector(

        onTap: () {
          setState(() {
            isDeliveryOpen =
                !isDeliveryOpen;
          });
        },

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [

            Text(
              "Delivery",

              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            AnimatedRotation(
              turns:
                  isDeliveryOpen
                      ? 0
                      : 0.5,

              duration:
                  Duration(milliseconds: 250),

              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      /// CONTENT
      AnimatedCrossFade(

        duration:
            Duration(milliseconds: 250),

        crossFadeState:
            isDeliveryOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,

        firstChild: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            SizedBox(height: 18),

            Text(
              data['deliveryText'] ??
                  "No delivery info available",

              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ],
        ),

        secondChild:
            SizedBox.shrink(),
      ),
    ],
  ),
),

                    SizedBox(height: 14),

                    /// 🔥 REVIEWS
                    buildSection("Reviews (Soon!)"),

                    SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            /// 🔥 BOTTOM BAR
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 22),

              decoration: BoxDecoration(
                color: Colors.black,

                border: Border(
                  top: BorderSide(
                    color: Colors.white10,
                  ),
                ),
              ),

              child: Row(
                children: [

                  /// 🔥 PRICE
                  Expanded(
                    child: Text(
                      "${product['price']} EGP",

                      style: TextStyle(
                        color:
                            const Color(0xFF4EA5FF),

                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 20),

                  /// 🔥 BUTTON
                  Expanded(
                    flex: 2,

                    child: SizedBox(
                      height: 68,

                      child: ElevatedButton(
                        onPressed: () async {
  final messenger = ScaffoldMessenger.of(context);

                          var index =
                              widget.cart.indexWhere(
                            (i) =>
                                i['name'] ==
                                    product['name'] &&
                                i['size'] ==
                                    selectedSize,
                          );

                          if (index != -1) {
                            widget.cart[index]
                                    ['quantity'] =
                                (widget.cart[index]
                                            ['quantity'] ??
                                        1) +
                                    quantity;
                          } else {
                            widget.cart.add({
                              "name": data['name'],
                              "price":
                                  data['price'],
                              "image": images
                                      .isNotEmpty
                                  ? images[0]
                                  : "",
                              "size":
                                  selectedSize,
                              "quantity":
                                  quantity,
                            });

                            widget.onAddToCart();
                          }

                          var user =
                              FirebaseAuth
                                  .instance
                                  .currentUser;

                          if (user != null) {

                            var cartRef =
                                FirebaseFirestore
                                    .instance
                                    .collection(
                                        'users')
                                    .doc(user.uid)
                                    .collection(
                                        'cart');

                            var existing =
                                await cartRef
                                    .where(
                                      "name",
                                      isEqualTo:
                                          product[
                                              'name'],
                                    )
                                    .where(
                                      "size",
                                      isEqualTo:
                                          selectedSize,
                                    )
                                    .get();

                            if (existing
                                .docs
                                .isNotEmpty) {

                              var doc =
                                  existing
                                      .docs
                                      .first;

                              await cartRef
                                  .doc(doc.id)
                                  .update({
                                "quantity":
                                    (doc['quantity'] ??
                                            1) +
                                        quantity,
                              });

                            } else {

                              await cartRef
                                  .add({
                                "name":
                                    data['name'],

                                "price":
                                    data['price'],

                                "image":
                                    images.isNotEmpty
                                        ? images[0]
                                        : "",

                                "size":
                                    selectedSize,

                                "quantity":
                                    quantity,
                              });
                            }
                          }

                          if (!mounted) return;

messenger.showSnackBar(
  const SnackBar(
    content: Text("Added to cart 🛒"),
  ),
);
                        },

                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              const Color(
                                  0xFF67B7FF),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(24),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,

                          children: [

                            Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 36,
                            ),

                            SizedBox(width: 12),

                            Text(
                              "Add to Cart",

                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Container(
            width: 8,
            height: 8,

            margin: EdgeInsets.only(top: 8),

            decoration: BoxDecoration(
              color: const Color(0xFF4EA5FF),
              shape: BoxShape.circle,
            ),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(
          horizontal: 22, vertical: 22),

      decoration: BoxDecoration(
        color: const Color(0xFF141118),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [

          Text(
            title,

            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}