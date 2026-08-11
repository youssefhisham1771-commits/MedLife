import 'package:flutter/material.dart';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {

  final reviewController = TextEditingController();

  int selectedRating = 0;

  bool isLoading = false;

late AnimationController _barsController;

@override
void initState() {
  super.initState();

  _barsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _barsController.forward();
  });
}

@override
void dispose() {
  _barsController.dispose();
  reviewController.dispose();
  super.dispose();
}

  Future<void> submitReview() async {

    var user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (selectedRating == 0 ||
        reviewController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Choose rating and write review"),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      var userData =
          userDoc.data() as Map<String, dynamic>;

      var existing = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existing.docs.isNotEmpty) {

        await FirebaseFirestore.instance
            .collection('reviews')
            .doc(existing.docs.first.id)
            .update({

          'rating': selectedRating,

          'review':
              reviewController.text.trim(),

          'createdAt': Timestamp.now(),
        });

      } else {

        await FirebaseFirestore.instance
            .collection('reviews')
            .add({

          'userId': user.uid,

          'userName':
              userData['name'] ?? "User",

          'rating': selectedRating,

          'review':
              reviewController.text.trim(),

          'createdAt': Timestamp.now(),
        });
      }

      reviewController.clear();

      setState(() {
        selectedRating = 0;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Review Submitted Successfully ⭐"),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error ❌"),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    const Color bgColor = Color(0xFF141118);

    const Color cardColor = Color(0xFF1D1B20);

    const Color blueColor = Color(0xFF6EA6C1);

    return Scaffold(

      backgroundColor: bgColor,

      appBar: AppBar(

  backgroundColor:
      isDark
          ? const Color(0xFF141118)
          : Colors.white,

  elevation: 0,

  leading: IconButton(
    icon: Icon(
      Icons.arrow_back,
      color:
          isDark
              ? Colors.white
              : Colors.black,
    ),

    onPressed: () {
      Navigator.pop(context);
    },
  ),

  title: Text(
    "Our Customers Reviews",

    style: TextStyle(
      color:
          isDark
              ? Colors.white
              : Colors.black,

      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
  ),
),

      body: StreamBuilder(

        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: blueColor,
              ),
            );
          }

          var reviews = snapshot.data!.docs;

          double average = 0;

          if (reviews.isNotEmpty) {

            int total = 0;

            for (var review in reviews) {
              total += review['rating'] as int;
            }

            average = total / reviews.length;
          }

          int star5 = 0;
          int star4 = 0;
          int star3 = 0;
          int star2 = 0;
          int star1 = 0;

          for (var review in reviews) {

            int rate = review['rating'];

            if (rate == 5) star5++;
            if (rate == 4) star4++;
            if (rate == 3) star3++;
            if (rate == 2) star2++;
            if (rate == 1) star1++;
          }

          double percent(int count) {

            if (reviews.isEmpty) return 0;

            return count / reviews.length;
          }

          return SingleChildScrollView(

            padding: EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// ⭐ AVERAGE
                Center(
 child: TweenAnimationBuilder<double>(
  duration: const Duration(
    milliseconds: 1800,
  ),
  curve: Curves.easeOutCubic,
  tween: Tween(
    begin: 0,
    end: average,
  ),

    builder: (context, animatedAverage, child) {

      return Column(
        children: [

          Text(
            animatedAverage.toStringAsFixed(1),

            style: TextStyle(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 8),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: List.generate(
              5,
              (index) {

                double fill =
                    animatedAverage - index;

                if (fill < 0) fill = 0;
                if (fill > 1) fill = 1;

                return Stack(
                  children: [

                    Icon(
                      Icons.star_border,
                      color: Color(0xFF6EA6C1),
                      size: 30,
                    ),

                    ClipRect(
                      child: Align(
                        alignment:
                            Alignment.centerLeft,

                        widthFactor: fill,

                        child: Icon(
                          Icons.star,
                          color:
                              Color(0xFF6EA6C1),
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          SizedBox(height: 8),

          Text(
            "Based on ${reviews.length} Reviews",

            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      );
    },
  ),
),

                SizedBox(height: 30),

                /// 📊 BARS
                buildRatingBar(
                    5,
                    percent(star5),
                    isDark),

                buildRatingBar(
                    4,
                    percent(star4),
                    isDark),

                buildRatingBar(
                    3,
                    percent(star3),
                    isDark),

                buildRatingBar(
                    2,
                    percent(star2),
                    isDark),

                buildRatingBar(
                    1,
                    percent(star1),
                    isDark),

                SizedBox(height: 35),

                /// ✍️ REVIEW CARD
                Container(

                  padding: EdgeInsets.all(20),

                  decoration: BoxDecoration(

                    color: cardColor,

                    borderRadius:
                        BorderRadius.circular(30),
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Rate Our App",

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 20),

                      /// ⭐ STARS
                      Row(
                        children: List.generate(
                          5,
                          (index) {

                            int star = index + 1;

                            return GestureDetector(

                              onTap: () {
                                setState(() {
                                  selectedRating = star;
                                });
                              },

                              child: AnimatedContainer(

                                duration:
                                    Duration(milliseconds: 200),

                                margin:
                                    EdgeInsets.only(right: 8),

                                child: Icon(

                                  star <= selectedRating
                                      ? Icons.star
                                      : Icons.star_border,

                                  color: blueColor,

                                  size: star == selectedRating
                                      ? 40
                                      : 34,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: 20),

                      /// ✍️ REVIEW FIELD
                      TextField(

                        controller: reviewController,

                        maxLines: 4,

                        style: TextStyle(
                          color: Colors.white,
                        ),

                        decoration: InputDecoration(

                          hintText:
                              "Write your review...",

                          hintStyle: TextStyle(
                            color: Colors.white70,
                          ),

                          filled: true,

                          fillColor:
                              bgColor,

                          border: OutlineInputBorder(

                            borderRadius:
                                BorderRadius.circular(20),

                            borderSide:
                                BorderSide.none,
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      /// 🚀 BUTTON
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton(

                          onPressed:
                              isLoading
                                  ? null
                                  : submitReview,

                          style:
                              ElevatedButton.styleFrom(

                            backgroundColor:
                                blueColor,

                            foregroundColor:
                                Colors.white,

                            padding:
                                EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),

                          child: isLoading
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "Submit Review",
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 35),

                /// 👥 REVIEWS
                Text(
                  "Users Reviews",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 20),

                if (reviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),

                      child: Text(
                        "No Reviews Yet ⭐",

                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                ...reviews.map((doc) {

                  var data =
                      doc.data();

                  return buildReviewCard(
                    data['userName'],
                    data['rating'],
                    data['review'],
                    isDark,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ⭐ BAR
  Widget buildRatingBar(
  int star,
  double value,
  bool isDark,
) {
  final double startDelay =
      (5 - star) * 0.12;

  return AnimatedBuilder(
    animation: _barsController,

    builder: (context, child) {

      double progress =
          ((_barsController.value - startDelay) /
                  (1 - startDelay))
              .clamp(0.0, 1.0);

      progress = Curves.easeOutCubic
          .transform(progress);

      final animatedValue =
          value * progress;

      return Padding(
        padding:
            const EdgeInsets.only(bottom: 14),

        child: Row(
          children: [

            Text(
              "$star",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.star,
              color: Color(0xFF6EA6C1),
              size: 18,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),

                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 10,
                  backgroundColor:
                      Colors.white12,

                  valueColor:
                      const AlwaysStoppedAnimation(
                    Color(0xFF6EA6C1),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 42,
              child: Text(
                "${(animatedValue * 100).toInt()}%",
                textAlign: TextAlign.end,

                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  /// 💬 REVIEW CARD
  Widget buildReviewCard(
      String name,
      int stars,
      String review,
      bool isDark,
      ) {

    return Container(

      margin: EdgeInsets.only(bottom: 20),

      padding: EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Color(0xFF1D1B20),

        borderRadius:
            BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              CircleAvatar(
                backgroundColor:
                    Color(0xFF6EA6C1),

                child: Text(
                  name[0].toUpperCase(),
                ),
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  name,

                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          Row(
            children: List.generate(
              stars,
                  (index) => Icon(
                Icons.star,
                color: Color(0xFF6EA6C1),
                size: 20,
              ),
            ),
          ),

          SizedBox(height: 12),

          Text(
            review,

            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}