import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  /// 🔗 OPEN LINKS
  static Future<void> openLink(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// 🔹 CONTACT CARD
  static Widget buildContactCard({
    required BuildContext context,
    String? imagePath,
    IconData? icon,
    Color? iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),

        color: isDark
            ? const Color(0xFF1D1B20)
            : Colors.black.withValues(alpha: 0.03),

        border: Border.all(
          color: isDark
              ? Colors.white10
              : Colors.black12,
        ),

        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset: Offset(0, 6),

            color: isDark
                ? Colors.black26
                : Colors.black12,
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(24),

          onTap: onTap,

          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),

            child: Row(
              children: [

                /// 🔥 ICON / IMAGE
                Container(
                  width: 70,
                  height: 70,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                  ),

                  child: imagePath != null
                      ? Padding(
                          padding:
                              const EdgeInsets.all(
                            14,
                          ),

                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(
                          icon,
                          size: 38,
                          color: iconColor,
                        ),
                ),

                SizedBox(width: 18),

                /// 🔥 TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        title,

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,

                          color: isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        subtitle,

                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "Tap to open",

                        style: TextStyle(
                          fontSize: 13,

                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ➜ ARROW
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF6EA6C1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF141118)
          : Colors.white,

      appBar: AppBar(
        title: Text(
          "Contact Us",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        elevation: 0,

        backgroundColor: isDark
            ? const Color(0xFF141118)
            : Colors.white,

        foregroundColor:
            isDark
                ? Colors.white
                : Colors.black,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),

        child: Column(
          children: [

            SizedBox(height: 10),

            /// 🎧 TOP ICON
            Container(
              padding: EdgeInsets.all(28),

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: isDark
                    ? const Color(0xFF1D1B20)
                    : Colors.black.withValues(alpha: 
                        0.04,
                      ),

                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.black12,
                ),
              ),

              child: Icon(
                Icons.support_agent_rounded,

                size: 70,

                color: const Color(
                  0xFF6EA6C1,
                ),
              ),
            ),

            SizedBox(height: 30),

            /// 🔥 TITLE
            Text(
              "We're Here For You",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,

                color: isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            SizedBox(height: 12),

            /// 🔥 SUBTITLE
            Text(
              "Feel free to contact us anytime you need help.",

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,

                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),

            SizedBox(height: 35),

            /// 📸 INSTAGRAM
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Instagram.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Instagram",

              subtitle: "@medlife_eg",

              onTap: () {
                openLink(
                  "https://www.instagram.com/medlife_eg?igsh=aWlxb20ybGZvamk2",
                );
              },
            ),

            /// 📘 FACEBOOK
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Facebook.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Facebook",

              subtitle: "MedLife",

              onTap: () {
                openLink(
                  "https://www.facebook.com/profile.php?id=61574319662590",
                );
              },
            ),

            /// 🎵 TIKTOK
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Tiktok.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "TikTok",

              subtitle: "@medlife_eg",

              onTap: () {
                openLink(
                  "https://www.tiktok.com/@medlife_eg",
                );
              },
            ),

            /// 💬 WHATSAPP
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Whatsapp.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "WhatsApp",

              subtitle:
                  "+20 1010 520 993",

              onTap: () {
                openLink(
                  "https://wa.me/201010520993",
                );
              },
            ),

            /// 📧 EMAIL
            buildContactCard(
              context: context,

              imagePath:
                  "assets/Gmail.png",

              bgColor:
                  const Color(0x336EA6C1),

              title: "Support Email",

              subtitle:
                  "medlife.supportteam@gmail.com",

              onTap: () {
                openLink(
                  "mailto:medlife.supportteam@gmail.com",
                );
              },
            ),

            SizedBox(height: 10),

            //// 🔒 PRIVACY
            Container(
              width: double.infinity,

              padding: EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                color: isDark
                    ? const Color(
                        0xFF1D1B20,
                      )
                    : Colors.black
                        .withValues(alpha: 0.03),

                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black12,
                ),

                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black
                            .withValues(alpha: 0.25)
                        : Colors.black
                            .withValues(alpha: 0.08),

                    blurRadius: 12,

                    offset: Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                children: [

                  Container(
                    padding: EdgeInsets.all(
                      12,
                    ),

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: const Color(
                        0x336EA6C1,
                      ),
                    ),

                    child: Icon(
                      Icons.shield_outlined,

                      color: const Color(
                        0xFF6EA6C1,
                      ),
                    ),
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          "We value your privacy",

                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,

                            fontSize: 16,

                            color: isDark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          "Your information is safe with us and will never be shared.",

                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
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
      ),
    );
  }
}