import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../repositories/cart_repository.dart';
import '../widgets/cart/cart_header.dart';
import '../services/promo_service.dart';
import '../widgets/cart/promo_box.dart';
import '../widgets/cart/cart_item_card.dart';
import '../widgets/cart/place_order_dialog.dart';
import '../services/cart_service.dart';


class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  TextEditingController promoController =
      TextEditingController();

      late List<Map<String, dynamic>> cart;

      final CartRepository _cartRepository = CartRepository();
      final PromoService _promoService = PromoService();
      final CartService _cartService = CartService();

  double discount = 0;
  double percent = 0;


Future<void> loadCart() async {
  final cart = await _cartRepository.loadCart();

  if (!mounted) return;

  setState(() {
  this.cart = List<Map<String, dynamic>>.from(cart);
});
}

  double getTotalBeforeDiscount() {
    double t = 0;

    for (var item in cart) {
      t +=
          double.parse(
            item["price"].toString(),
          ) *
          (item["quantity"] ?? 1);
    }

    return t;
  }

  double total() {
    return getTotalBeforeDiscount() -
        discount;
  }

Future<void> applyPromo() async {
  final code = promoController.text.trim();

  final value = await _promoService.getDiscount(code);

  if (!mounted) return;

  if (value == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("كود غير صحيح ❌"),
      ),
    );
    return;
  }

  percent = value;

  setState(() {
    discount = getTotalBeforeDiscount() * (percent / 100);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("تم تطبيق خصم $percent%"),
    ),
  );
}

 @override
void initState() {
  super.initState();

  cart = List<Map<String, dynamic>>.from(widget.cart);

  loadCart();
}

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  });

  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0713),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0713),

        elevation: 0,
        toolbarHeight: 0,
      ),

      body: cart.isEmpty
          ? Center(
              child: Text(
                "Cart is empty",

                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )
          : ListView(
              padding:
                  EdgeInsets.all(16),

              children: [

CartHeader(
  itemCount: cart.length,
),

                ...List.generate(
                  cart.length,
                  (i) {
                    return CartItemCard(
  item: cart[i],

  onDelete: () async {
    await _cartService.removeItem(
  cart[i]['docId'],
);

    setState(() {
      cart.removeAt(i);
    });

    final t = getTotalBeforeDiscount();

    setState(() {
      discount = t * (percent / 100);
    });
  },

  onIncrease: () async {
    setState(() {
      cart[i]["quantity"]++;
    });

    await _cartService.updateQuantity(
  cart[i]['docId'],
  cart[i]['quantity'],
);
  },

  onDecrease: () async {
    if ((cart[i]["quantity"] ?? 1) > 1) {
      setState(() {
        cart[i]["quantity"]--;
      });

      await _cartService.updateQuantity(
  cart[i]['docId'],
  cart[i]['quantity'],
);
    }
  },
);
                  },
                ),

                PromoBox(
  controller: promoController,
  onApply: applyPromo,
),

                SizedBox(height: 18),

                Container(
                  padding:
                      EdgeInsets.all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFF141118,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    border: Border.all(
                      color:
                          Colors.white10,
                    ),
                  ),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Subtotal",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),

                          Text(
                            "${getTotalBeforeDiscount().toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Discount",

                            style:
                                TextStyle(
                              color:
                                  Colors.white70,

                              fontSize:
                                  20,
                            ),
                          ),

                          Text(
                            "- ${discount.toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF6EA6C1,
                              ),

                              fontSize:
                                  20,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Divider(
                        height: 35,
                        color:
                            Colors.white12,
                      ),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,

                        children: [
                          Text(
                            "Total",

                            style:
                                TextStyle(
                              color:
                                  Colors.white,

                              fontSize:
                                  28,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Text(
                            "${total().toStringAsFixed(1)} EGP",

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF6EA6C1,
                              ),

                              fontSize:
                                  32,

                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22),

                SizedBox(
                  height: 68,
                  width: double.infinity,

                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      if (widget
                          .cart.isEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              "الكارت فاضي ❌",
                            ),
                          ),
                        );

                        return;
                      }

                      showDialog(
  context: context,
  builder: (_) => PlaceOrderDialog(
    cart: cart,
    total: total(),
    discount: discount,
    onOrderPlaced: () {
      setState(() {
        cart.clear();
        discount = 0;
      });
    },
  ),
);
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6EA6C1,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                    ),

                    icon: Icon(
                      Icons
                          .shopping_bag_outlined,

                      color: Colors.white,
                    ),

                    label: Text(
                      "Place Order",

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 22,

                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
              ],
            ),
    );
  }

  @override
  void dispose() {
    promoController.dispose();

    super.dispose();
  }
}