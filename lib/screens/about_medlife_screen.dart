import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutMedLifeScreen extends StatelessWidget {
  const AboutMedLifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDark ? const Color(0xFF0D0917) : const Color(0xFFF3F3F5);

    final Color cardColor =
        isDark ? const Color(0xFF1D1B20) : Colors.white;

    final Color boxColor =
        isDark ? const Color(0xFF2A2730) : const Color(0xFFF4F4F4);

    final Color mainText =
        isDark ? Colors.white : Colors.black;

    final Color subText =
        isDark ? Colors.white70 : Colors.grey.shade700;

    const Color primaryBlue = Color(0xFF6EA6C1);

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        title: Text(
          "About MedLife",
          style: TextStyle(color: mainText),
        ),
        backgroundColor:
            isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: mainText),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /// 🔥 TOP CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),

                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF26222D),
                          const Color(0xFF1D1B20),
                        ]
                      : [
                          Colors.white,
                          const Color(0xFFF5F5F5),
                        ],
                ),
              ),

              child: Row(
                children: [

                  Column(
                    children: [

                      const Icon(
                        Icons.favorite,
                        color: primaryBlue,
                        size: 50,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "MedLife",
                        style: TextStyle(
                          color: mainText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "For a better healthcare",
                        style: TextStyle(
                          color: subText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Text(
                      "MedLife is your trusted destination for high-quality medical scrubs, lab coats, and medical accessories.",
                      style: TextStyle(
                        color: subText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔥 VISION & MISSION
            Row(
              children: [

                Expanded(
                  child: _box(
                    icon: Icons.remove_red_eye,
                    title: "Our Vision",
                    text:
                        "To become the leading destination in the Middle East.",
                    cardColor: cardColor,
                    mainText: mainText,
                    subText: subText,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _box(
                    icon: Icons.track_changes,
                    title: "Our Mission",
                    text:
                        "Provide high quality with best price.",
                    cardColor: cardColor,
                    mainText: mainText,
                    subText: subText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 SERVICES
            _section(
              "Our Services",
              [
                _iconItem(
                  Icons.medical_services,
                  "Scrubs",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.science,
                  "Lab Coats",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.healing,
                  "Accessories",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.local_shipping,
                  "Shipping",
                  boxColor,
                  subText,
                ),
              ],
              cardColor,
              mainText,
            ),

            const SizedBox(height: 20),

            /// 🔥 WHY CHOOSE US
            _section(
              "Why Choose MedLife?",
              [
                _iconItem(
                  Icons.star,
                  "High Quality",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.attach_money,
                  "Affordable",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.flash_on,
                  "Fast",
                  boxColor,
                  subText,
                ),

                _iconItem(
                  Icons.verified,
                  "Trusted",
                  boxColor,
                  subText,
                ),
              ],
              cardColor,
              mainText,
            ),

            const SizedBox(height: 20),

            /// 🔥 CONTACT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    "Contact Us",
                    style: TextStyle(
                      color: mainText,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [

                      const Icon(
                        Icons.phone,
                        color: primaryBlue,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        "01010520993",
                        style: TextStyle(
                          color: subText,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      const Icon(
                        Icons.email,
                        color: primaryBlue,
                      ),

                      const SizedBox(width: 10),

                      GestureDetector(
                        onTap: () async {

                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'medlife.supportteam@gmail.com',
                            query:
                                'subject=MedLife Support',
                          );

                          await launchUrl(emailUri);
                        },

                        child: Text(
                          "medlife.supportteam@gmail.com",
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration:
                                TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 CARD
  Widget _box({
    required IconData icon,
    required String title,
    required String text,
    required Color cardColor,
    required Color mainText,
    required Color subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            color: Color(0xFF6EA6C1),
            size: 32,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mainText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 SECTION
  Widget _section(
    String title,
    List<Widget> items,
    Color cardColor,
    Color mainText,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            title,
            style: TextStyle(
              color: mainText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: items,
          ),
        ],
      ),
    );
  }

  /// 🔹 ICON ITEM
  Widget _iconItem(
    IconData icon,
    String text,
    Color boxColor,
    Color subText,
  ) {
    return Container(
      width: 120,

      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),

      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 32,
            color: const Color(0xFF6EA6C1),
          ),

          const SizedBox(height: 10),

          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}