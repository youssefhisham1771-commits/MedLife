import 'package:flutter/material.dart';
import 'orders_list_screen.dart';


class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return DefaultTabController(
      length: 2,

      child: Column(
        children: [

          const SizedBox(height: 12),

          /// 🔥 TAB BAR
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),

            padding: EdgeInsets.all(6),

            decoration: BoxDecoration(
              color: const Color(0xFF141118),

              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: Colors.white10,
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .35),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),

            child: TabBar(

              dividerColor: Colors.transparent,

              indicator: BoxDecoration(
                color: const Color(0xFF6EA6C1),

                borderRadius: BorderRadius.circular(14),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6EA6C1)
                        .withValues(alpha: .35),

                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),

              indicatorSize: TabBarIndicatorSize.tab,

              labelColor: Colors.white,

              unselectedLabelColor: Colors.white60,

              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),

              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),

              tabs: [

                /// 🟠 PENDING
                Container(
                  height: 52,

                  alignment: Alignment.center,

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Text(
                        "Pending",
                      ),

                      SizedBox(width: 6),

                      Container(
                        width: 10,
                        height: 10,

                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🟢 DELIVERED
                Container(
                  height: 52,

                  alignment: Alignment.center,

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [

                      Text(
                        "Delivered",
                      ),

                      SizedBox(width: 6),

                      Container(
                        width: 10,
                        height: 10,

                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          /// 🔥 ORDERS
          Expanded(
            child: Container(

              margin: EdgeInsets.symmetric(horizontal: 10),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),

              child: TabBarView(
                children: [

                  /// 🟠 Pending
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),

                    child: OrdersList(
                      status: "pending",
                    ),
                  ),

                  /// 🟢 Delivered
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),

                    child: OrdersList(
                      status: "delivered",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}