import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_addresses_screen.dart';
import 'about_medlife_screen.dart';



class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor =
        isDark ? Colors.white : Colors.black;

    final Color subTextColor =
        isDark ? Colors.white70 : Colors.grey.shade700;

    final Color cardColor =
        isDark
            ? const Color(0xFF1D1B20)
            : Colors.white;

    final Color iconBoxColor =
        isDark
            ? const Color(0xFF2A2730)
            : const Color(0xFFF3F3F3);

    final Color blueColor =
        isDark
            ? const Color(0xFF6EA6C1)
            : const Color(0xFF2D5A74);

    return Scaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF141118)
              : const Color(0xFFF7F7FA),

      appBar: AppBar(
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: mainTextColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "My Profile",
          style: TextStyle(
            color: mainTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: blueColor,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: user == null
          ? Center(
              child: Text(
                "No User Found",
                style: TextStyle(
                  color: mainTextColor,
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      "User data not found",
                      style: TextStyle(
                        color: mainTextColor,
                      ),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>;

                final String name =
                    data['name'] ?? 'No Name';

                final String email =
                    data['email'] ?? 'No Email';

                final String phone =
                    data['phone'] ?? 'No Phone';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// PROFILE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor:
                                  blueColor.withValues(alpha: .15),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: blueColor,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: mainTextColor,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Always remember, We care about you! ♡",
                              style: TextStyle(
                                fontSize: 15,
                                color: subTextColor,
                              ),
                            ),

                            const SizedBox(height: 24),

                            _buildInfoTile(
                              icon: Icons.email,
                              title: "Email",
                              value: email,
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.phone,
                              title: "Phone",
                              value: phone,
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),

                            const SizedBox(height: 14),

                            _buildInfoTile(
                              icon: Icons.calendar_month,
                              title: "Member Since",
                              value: user!.metadata.creationTime != null
                                  ? DateFormat.yMMMM().format(
                                      user!.metadata.creationTime!,
                                    )
                                  : "Unknown",
                              mainTextColor: mainTextColor,
                              subTextColor: subTextColor,
                              iconBoxColor: iconBoxColor,
                              blueColor: blueColor,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// MENU CARD
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _menuTile(
                              icon: Icons.location_on_outlined,
                              title: "My Addresses",
                              color: mainTextColor,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyAddressesScreen(),
                                  ),
                                );
                              },
                            ),

                            _menuTile(
  icon: Icons.credit_card,
  title: "Payment Methods",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

_menuTile(
  icon: Icons.notifications_none,
  title: "Notifications",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

_menuTile(
  icon: Icons.help_outline,
  title: "Help & Support",
  color: mainTextColor,

  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Will Be Available Soon!",
        ),
      ),
    );
  },
),

                            _menuTile(
                              icon: Icons.info_outline,
                              title: "About MedLife",
                              color: mainTextColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AboutMedLifeScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// LOGOUT
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Colors.red,
                          ),
                          title: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.red,
                          ),
                          onTap: () async {

  final navigator = Navigator.of(context);

  await FirebaseAuth.instance.signOut();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => LoginScreen(),
    ),
    (route) => false,
  );
},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color mainTextColor,
    required Color subTextColor,
    required Color iconBoxColor,
    required Color blueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBoxColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: blueColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6EA6C1),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}