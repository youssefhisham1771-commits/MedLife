import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

final cloudinary = CloudinaryPublic(
  'dzlorraqi',
  'Medlife',
  cache: false,
);

class BannerSlider extends StatefulWidget {
  final bool isAdmin;

  const BannerSlider({
    super.key,
    required this.isAdmin,
  });

  @override
State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  late PageController _controller;
  int currentPage = 0;
  Timer? timer;
  int bannersLength = 0;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      viewportFraction: 0.9,
      initialPage: 1000,
    );

    currentPage = 1000;

    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_controller.hasClients) {
        currentPage++;

        _controller.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<String?> uploadBannerToCloudinary() async {
    try {
      final picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return null;

      setState(() {
        isUploading = true;
      });

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          pickedFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      if (!mounted) return null;

      setState(() {
        isUploading = false;
      });

      return response.secureUrl;
    } catch (e) {
      if (mounted) {
  setState(() {
    isUploading = false;
  });
}

      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Upload Failed ❌"),
        ),
      );

      return null;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .snapshots(),
      builder: (context, snapshot) {
        var banners = snapshot.hasData
            ? snapshot.data!.docs
            : [];

        bannersLength = banners.length;

        return Column(
  children: [
    SizedBox(
      height: 190,

      child: Stack(
        children: [

          /// 🔥 LOADING
          if (!snapshot.hasData)
            Center(
              child: CircularProgressIndicator(),
            )

          /// 🔥 EMPTY
          else if (banners.isEmpty)
            Center(
              child: const Text(
                "No Banners",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            )

          /// 🔥 BANNERS
          else
            PageView.builder(
              controller: _controller,
              itemCount: null,

              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },

              itemBuilder: (context, index) {

                var data =
                    banners[index % banners.length];

                return AnimatedBuilder(
                  animation: _controller,

                  builder: (context, child) {

                    double value = 1;
                    double parallax = 0;

                    if (_controller
                        .position
                        .haveDimensions) {

                      double page =
                          _controller.page ?? 0;

                      value = (1 -
                              ((page - index)
                                      .abs() *
                                  0.2))
                          .clamp(0.85, 1.0);

                      parallax =
                          (page - index) * 40;
                    }

                    return Transform.scale(
                      scale: value,

                      child: Transform.translate(
                        offset: Offset(
                          parallax,
                          0,
                        ),

                        child: child,
                      ),
                    );
                  },

                  child: Stack(
                    children: [

                      /// 🔥 BANNER IMAGE
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 6,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(24),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: .35),

                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),

                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(24),

                          child: Image.network(
                            data['image'],

                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),

                      /// 🔥 DARK OVERLAY
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 6,
                        ),

                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(24),

                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,

                            colors: [
                              Colors.black.withValues(alpha: .15),
                              Colors.black.withValues(alpha: .05),
                            ],
                          ),
                        ),
                      ),

                      /// 🔥 MORE BUTTON
                      if (widget.isAdmin)
                        Positioned(
                          top: 12,
                          right: 18,

                          child: PopupMenuButton<String>(
                            color: Color(0xFF111827),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      18),
                            ),

                            onSelected:
                                (value) async {

                              /// ➕ ADD
                              if (value == "add") {

                                String? imageUrl =
                                    await uploadBannerToCloudinary();

                                    if (!mounted) return;

                                if (imageUrl != null) {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'banners')
                                      .add({
                                    "image":
                                        imageUrl,
                                  });

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(
                                          this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Banner Added ✅",
                                      ),
                                    ),
                                  );
                                }
                              }

                              /// ✏️ EDIT
                              if (value == "edit") {

                                String? newImage =
                                    await uploadBannerToCloudinary();

                                    if (!mounted) return;

                                if (newImage != null) {

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                          'banners')
                                      .doc(data.id)
                                      .update({
                                    "image":
                                        newImage,
                                  });

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(
                                          this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Banner Updated ✅",
                                      ),
                                    ),
                                  );
                                }
                              }

                              /// 🗑 DELETE
                              if (value == "delete") {

                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                        'banners')
                                    .doc(data.id)
                                    .delete();

                                    if (!mounted) return;

                                ScaffoldMessenger.of(
                                        this.context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Banner Deleted 🗑",
                                    ),
                                  ),
                                );
                              }
                            },

                            itemBuilder: (context) => [

                              /// ➕ ADD
                              PopupMenuItem(
                                value: "add",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.add,
                                      color: Color(
                                          0xFF6EA6C1),
                                    ),

                                    SizedBox(width: 10),

                                    const Text(
                                      "Add Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// ✏️ EDIT
                              PopupMenuItem(
                                value: "edit",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.edit,
                                      color: Color(
                                          0xFF6EA6C1),
                                    ),

                                    SizedBox(width: 10),

                                    const Text(
                                      "Edit Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 🗑 DELETE
                              PopupMenuItem(
                                value: "delete",

                                child: Row(
                                  children: [

                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),

                                    SizedBox(width: 10),

                                    const Text(
                                      "Delete Banner",

                                      style: TextStyle(
                                        color:
                                            Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            child: Container(
                              width: 48,
                              height: 48,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                color: Colors.black
                                    .withValues(alpha: .45),

                                border: Border.all(
                                  color: Colors.white10,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: .3),

                                    blurRadius: 10,
                                    offset: Offset(
                                      0,
                                      4,
                                    ),
                                  ),
                                ],
                              ),

                              child: isUploading
                                  ? Padding(
                                      padding:
                                          EdgeInsets.all(
                                              12),

                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.more_vert,
                                      color:
                                          Colors.white,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ),

    /// 🔥 INDICATOR
    if (banners.isNotEmpty)
      Padding(
        padding: EdgeInsets.only(top: 10),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: List.generate(
            banners.length,

            (index) {

              bool active =
                  currentPage % banners.length ==
                      index;

              return AnimatedContainer(
                duration: const Duration(
                  milliseconds: 300,
                ),

                margin: EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                width: active ? 18 : 7,
                height: 7,

                decoration: BoxDecoration(

                  borderRadius:
                      BorderRadius.circular(20),

                  gradient: active
                      ? LinearGradient(
                          colors: [
                            Color(0xFF6EA6C1),
                            Color(0xFF3B82F6),
                          ],
                        )
                      : null,

                  color: active
                      ? null
                      : Colors.grey.shade700,

                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Color(0xFF6EA6C1)
                                .withValues(alpha: .5),

                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              );
            },
          ),
        ),
      ),
  ],
);
      },
    );
  }
}