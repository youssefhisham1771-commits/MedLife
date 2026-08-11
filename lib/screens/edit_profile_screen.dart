import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_screen.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {

  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController oldPasswordController =
      TextEditingController();

  final TextEditingController newPasswordController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool isLoading = false;

  final Color purpleColor =
      const Color(0xFF6EA6C1);

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

        if (!mounted) return;

    if (doc.exists) {

      final data = doc.data()!;

      nameController.text =
          data['name'] ?? '';

      phoneController.text =
          data['phone'] ?? '';

      emailController.text =
          data['email'] ?? '';
    }
  }

  Future<void> saveChanges() async {

    try {

      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({

        'name':
            nameController.text.trim(),

        'phone':
            phoneController.text.trim(),

        'email':
            emailController.text.trim(),
      });

      if (emailController.text.trim()
          != user!.email) {

        await user!.verifyBeforeUpdateEmail(
          emailController.text.trim(),
        );
      }

      if (oldPasswordController
              .text
              .isNotEmpty &&
          newPasswordController
              .text
              .isNotEmpty) {

        AuthCredential credential =
            EmailAuthProvider.credential(

          email: user!.email!,

          password:
              oldPasswordController.text.trim(),
        );

        await user!
            .reauthenticateWithCredential(
          credential,
        );

        await user!.updatePassword(
          newPasswordController.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
              "Profile Updated Successfully ✅"),
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message =
          e.message ?? "Error";

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final Color bgColor =
        isDark
            ? const Color(0xFF141118)
            : const Color(0xFFF7F7FA);

    final Color cardColor =
        isDark
            ? const Color(0xFF1D1B20)
            : Colors.white;

    final Color textColor =
        isDark
            ? Colors.white
            : Colors.black;

    final Color subTextColor =
        isDark
            ? Colors.white70
            : Colors.grey.shade700;

    final Color iconBoxColor =
        isDark
            ? const Color(0xFF2E2B31)
            : const Color(0xFFF3F3F3);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

        backgroundColor:
            isDark
                ? Colors.black
                : Colors.white,

        elevation: 0,

        leading: IconButton(

          icon: Icon(
            Icons.arrow_back,
            color: textColor,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(

          "Edit Profile",

          style: TextStyle(
            color: textColor,
            fontWeight:
                FontWeight.bold,
            fontSize: 28,
          ),
        ),

        actions: [

          TextButton(

            onPressed:
                isLoading
                    ? null
                    : saveChanges,

            child: Text(

              "Save",

              style: TextStyle(
                color: purpleColor,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          )
        ],
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Container(

          padding:
              const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: cardColor,

            borderRadius:
                BorderRadius.circular(24),
          ),

          child: Column(

            children: [

              CircleAvatar(

                radius: 50,

                backgroundColor:
                    iconBoxColor,

                child: Icon(

                  Icons.person,

                  size: 55,

                  color: purpleColor,
                ),
              ),

              const SizedBox(height: 16),

              Text(

                "Always remember, We care about you! ♡",

                style: TextStyle(
                  color: subTextColor,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 30),

              _buildTextField(

                controller:
                    nameController,

                label: "Full Name",

                icon:
                    Icons.person_outline,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 18),

              _buildTextField(

                controller:
                    emailController,

                label:
                    "Email Address",

                icon:
                    Icons.email_outlined,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 18),

              _buildTextField(

                controller:
                    phoneController,

                label:
                    "Phone Number",

                icon:
                    Icons.phone_outlined,

                textColor: textColor,

                cardColor: cardColor,

                iconBoxColor:
                    iconBoxColor,
              ),

              const SizedBox(height: 25),

              Align(

                alignment:
                    Alignment.centerLeft,

                child: Text(

                  "Change Password",

                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                    oldPasswordController,

                obscureText:
                    obscureOldPassword,

                style: TextStyle(
                  color: textColor,
                ),

                decoration: InputDecoration(

                  labelText:
                      "Old Password",

                  labelStyle:
                      TextStyle(
                    color:
                        subTextColor,
                  ),

                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color:
                        purpleColor,
                  ),

                  suffixIcon:
                      IconButton(

                    icon: Icon(

                      obscureOldPassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,

                      color:
                          purpleColor,
                    ),

                    onPressed: () {

                      setState(() {

                        obscureOldPassword =
                            !obscureOldPassword;
                      });
                    },
                  ),

                  filled: true,

                  fillColor:
                      cardColor,

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),

                    borderSide:
                        BorderSide(
                      color:
                          iconBoxColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                    newPasswordController,

                obscureText:
                    obscureNewPassword,

                style: TextStyle(
                  color: textColor,
                ),

                decoration: InputDecoration(

                  labelText:
                      "New Password",

                  labelStyle:
                      TextStyle(
                    color:
                        subTextColor,
                  ),

                  prefixIcon: Icon(
                    Icons.lock,
                    color:
                        purpleColor,
                  ),

                  suffixIcon:
                      IconButton(

                    icon: Icon(

                      obscureNewPassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,

                      color:
                          purpleColor,
                    ),

                    onPressed: () {

                      setState(() {

                        obscureNewPassword =
                            !obscureNewPassword;
                      });
                    },
                  ),

                  filled: true,

                  fillColor:
                      cardColor,

                  border:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),

                  enabledBorder:
                      OutlineInputBorder(

                    borderRadius:
                        BorderRadius.circular(
                            18),

                    borderSide:
                        BorderSide(
                      color:
                          iconBoxColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(

                alignment:
                    Alignment.centerRight,

                child: GestureDetector(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                            ForgotPasswordScreen(),
                      ),
                    );
                  },

                  child: Text(

                    "Forgot my password?",

                    style: TextStyle(
                      color:
                          purpleColor,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(

                width: double.infinity,

                height: 58,

                child: ElevatedButton(

                  onPressed:
                      isLoading
                          ? null
                          : saveChanges,

                  style:
                      ElevatedButton.styleFrom(

                    backgroundColor:
                        purpleColor,

                    shape:
                        RoundedRectangleBorder(

                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),

                  child: isLoading

                      ? const CircularProgressIndicator(
                          color:
                              Colors.white,
                        )

                      : const Text(

                          "Save Changes",

                          style: TextStyle(

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,

                            color:
                                Colors.white,
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({

    required TextEditingController
        controller,

    required String label,

    required IconData icon,

    required Color textColor,

    required Color cardColor,

    required Color iconBoxColor,

    bool enabled = true,
  }) {

    return TextField(

      controller: controller,

      enabled: enabled,

      style: TextStyle(
        color: textColor,
      ),

      decoration: InputDecoration(

        labelText: label,

        labelStyle: TextStyle(
          color: Colors.grey,
        ),

        prefixIcon: Icon(
          icon,
          color: purpleColor,
        ),

        filled: true,

        fillColor: cardColor,

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),
        ),

        enabledBorder:
            OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(18),

          borderSide: BorderSide(
            color: iconBoxColor,
          ),
        ),
      ),
    );
  }
}