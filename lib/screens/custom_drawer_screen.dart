import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'reviews_screen.dart';
import 'contact_us_screen.dart';


class CustomDrawerScreen extends StatelessWidget {
  const CustomDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        margin: EdgeInsets.only(
          top: 60,
          right: 10,
          bottom: 60,
        ),
        padding: EdgeInsets.all(15),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),

          gradient: LinearGradient(
            colors: [
              Color(0xFF2D5A74),
              Color(0xFF123249),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black26,
            ),
          ],
        ),

        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),

          builder: (context, snapshot) {

            Map<String, dynamic> data = {};

            if (snapshot.hasData &&
                snapshot.data!.exists) {
              data =
                  snapshot.data!.data()
                      as Map<String, dynamic>;
            }

            String userName =
                data['name'] ?? "User";


            String memberSince = "Unknown";

if (user?.metadata.creationTime != null) {

  DateTime createdAt =
      user!.metadata.creationTime!;

  List months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  memberSince =
      "${months[createdAt.month - 1]} ${createdAt.year}";
}

            return SingleChildScrollView(
              physics: BouncingScrollPhysics(),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  /// 🔥 HEADER
                  Container(
                    padding: EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(24),

                      gradient: LinearGradient(
                        colors: [
                          Color(0xff133B63),
                          Color(0xff0B2340),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),

                    child: Column(
                      children: [

                        /// USER INFO
                        Row(
                          children: [

                            Container(
                              width: 58,
                              height: 58,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                border: Border.all(
                                  color:
                                      Color(0xff58D0FF),
                                  width: 2,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xff58D0FF,
                                    ).withValues(alpha: .4),

                                    blurRadius: 15,
                                  ),
                                ],
                              ),

                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [

                                  Text(
                                    userName,

                                    maxLines: 1,

                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style: TextStyle(
                                      color:
                                          Colors.white,

                                      fontWeight:
                                          FontWeight
                                              .bold,

                                      fontSize: 16,
                                    ),
                                  ),

                                  SizedBox(height: 3),

                                  Text(
                                    "Valued Customer",

                                    style: TextStyle(
                                      color: Color(
                                        0xff6DD5FF,
                                      ),

                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        /// 🔥 STATS
                        Container(
                          padding:
                              EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),

                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),

                            color: Colors.white
                                .withValues(alpha: .05),

                            border: Border.all(
                              color: Colors.white10,
                            ),
                          ),

                          child: Row(
                            children: [

                              Expanded(
                                child: Row(
                                  children: [

                                    Icon(
                                      Icons
                                          .verified_user,

                                      color: Color(
                                        0xff58D0FF,
                                      ),

                                      size: 22,
                                    ),

                                    SizedBox(width: 6),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [

                                          Text(
                                            "Member since",

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors
                                                      .white70,

                                              fontSize:
                                                  10,
                                            ),
                                          ),

                                          SizedBox(
                                            height: 2,
                                          ),

                                          Text(
                                            memberSince,

                                            overflow:
                                                TextOverflow
                                                    .ellipsis,

                                            style:
                                                TextStyle(
                                              color:
                                                  Colors
                                                      .white,

                                              fontWeight:
                                                  FontWeight
                                                      .bold,

                                              fontSize:
                                                  13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                width: 1,
                                height: 35,
                                color: Colors.white12,
                              ),

                              SizedBox(width: 8),

                              Expanded(
                                child:
                                    FutureBuilder<
                                        QuerySnapshot>(
                                  future:
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                            'orders',
                                          )
                                          .where(
                                            'userId',
                                            isEqualTo:
                                                user
                                                    ?.uid,
                                          )
                                          .get(),

                                  builder:
                                      (context,
                                          orderSnap) {

                                    int totalOrders =
                                        orderSnap
                                            .data
                                            ?.docs
                                            .length ??
                                        0;

                                    return Row(
                                      children: [

                                        Icon(
                                          Icons
                                              .shopping_bag,

                                          color: Color(
                                            0xff58D0FF,
                                          ),

                                          size: 22,
                                        ),

                                        SizedBox(
                                          width: 6,
                                        ),

                                        Expanded(
                                          child:
                                              Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,

                                            children: [

                                              Text(
                                                "Total Orders",

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors
                                                          .white70,

                                                  fontSize:
                                                      10,
                                                ),
                                              ),

                                              SizedBox(
                                                height:
                                                    2,
                                              ),

                                              Text(
                                                "$totalOrders Orders",

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    TextStyle(
                                                  color:
                                                      Colors
                                                          .white,

                                                  fontWeight:
                                                      FontWeight
                                                          .bold,

                                                  fontSize:
                                                      13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  /// 🔥 ITEMS
                  drawerItem(
                    context,

                    icon: Icons.person,

                    title: "My Profile",

                    subtitle:
                        "View and edit your information",

                    iconColor: Color(0xff4C7DFF),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  drawerItem(
                    context,

                    icon: Icons.star,

                    title:
                        "Our Customers Reviews",

                    subtitle:
                        "See what our customers say",

                    iconColor: Colors.amber,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ReviewsScreen(),
                        ),
                      );
                    },
                  ),

                  drawerItem(
                    context,

                    icon: Icons.support_agent,

                    title: "Contact Us",

                    subtitle:
                        "We're here to help you",

                    iconColor: Colors.white,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  ContactUsScreen(),
                        ),
                      );
                    },
                  ),

                  Divider(
                    color: Colors.white10,
                    height: 24,
                  ),

                  drawerItem(
                    context,

                    icon: Icons.settings,

                    title: "Settings",

                    subtitle: "App preferences",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  drawerItem(
                    context,

                    icon: Icons.privacy_tip,

                    title: "Privacy Policy",

                    subtitle:
                        "Your data is safe with us",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  drawerItem(
                    context,

                    icon: Icons.description,

                    title:
                        "Terms & Conditions",

                    subtitle:
                        "Read our terms of service",

                    iconColor: Colors.white,

                    onTap: () {},
                  ),

                  SizedBox(height: 12),

                  /// 🔥 LOGOUT
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),

                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: .18),

                          Colors.pink.withValues(alpha: 
                            .08,
                          ),
                        ],
                      ),
                    ),

                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),

                      leading: Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),

                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.redAccent,
                        size: 16,
                      ),

                      title: Text(
                        "Logout",

                        style: TextStyle(
                          color: Colors.redAccent,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 15,
                        ),
                      ),

                      subtitle: Text(
                        "Sign out from your account",

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 11,
                        ),
                      ),

                      onTap: () async {

  await FirebaseAuth.instance.signOut();

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => LoginScreen(),
    ),
    (route) => false,
  );
},
                    ),
                  ),

                  SizedBox(height: 14),

                  /// 🔥 SUPPORT BOX
                  Container(
                    padding: EdgeInsets.all(10),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(20),

                      color: Colors.white
                          .withValues(alpha: .05),

                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),

                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 20,

                          backgroundColor:
                              Colors.white
                                  .withValues(alpha: .08),

                          child: Icon(
                            Icons.headset_mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [

                              Text(
                                "Need help?",

                                style: TextStyle(
                                  color:
                                      Colors.white,

                                  fontWeight:
                                      FontWeight
                                          .bold,

                                  fontSize: 14,
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
  "Medlife.supportteam@gmail.com",

  maxLines: 1,

  overflow: TextOverflow.ellipsis,

  style: TextStyle(
    color: Color(0xff58D0FF),
    fontSize: 11,
  ),
),
                            ],
                          ),
                        ),

                        InkWell(
  onTap: () async {

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path:
          'Medlife.supportteam@gmail.com',
    );

    await launchUrl(emailLaunchUri);
  },

  child: CircleAvatar(
    radius: 20,
    backgroundColor: Color(0xff256DFF),

    child: Icon(
      Icons.email,
      color: Colors.white,
      size: 18,
    ),
  ),
),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget drawerItem(
    BuildContext context, {

    required IconData icon,

    required String title,

    required String subtitle,

    required Color iconColor,

    required VoidCallback onTap,
  }) {

    return Padding(
      padding: EdgeInsets.only(bottom: 10),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(20),

          onTap: onTap,

          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(20),

              color:
                  Colors.white.withValues(alpha: .03),
            ),

            child: Row(
              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    color: Colors.white
                        .withValues(alpha: .05),
                  ),

                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        title,

                        style: TextStyle(
                          color: Colors.white,

                          fontWeight:
                              FontWeight.bold,

                          fontSize: 15,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        subtitle,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 4),

                Icon(
                  Icons.arrow_forward_ios,

                  color: Colors.white70,

                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}