import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class OrderDetailsScreen extends StatelessWidget {

  final dynamic order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  Future<void> callCustomer(String phone) async {

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: phone,
  );

  if (await canLaunchUrl(phoneUri)) {

    await launchUrl(phoneUri);

  } else {

    throw 'Could not launch phone';
  }
}

Future<void> chatCustomer(String phone) async {

  String cleanedPhone =
      phone.replaceAll(RegExp(r'[^0-9]'), '');

  if (cleanedPhone.startsWith('0')) {

    cleanedPhone =
        '20${cleanedPhone.substring(1)}';
  }

  final Uri whatsappUri = Uri.parse(
    "https://wa.me/$cleanedPhone",
  );

  if (await canLaunchUrl(whatsappUri)) {

    await launchUrl(
      whatsappUri,
      mode:
          LaunchMode.externalApplication,
    );

  } else {

    throw 'Could not launch WhatsApp';
  }
}

  double parseToDouble(dynamic value) {

    if (value == null) return 0;

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int parseToInt(dynamic value) {

    if (value == null) return 0;

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {

    final data =
        order.data()
            as Map<String, dynamic>;

    List items =
        data['items'] ?? [];

    String customerName =
        data['name'] ??
            'Unknown';

    String phone =
        data['phone'] ??
            '';

    String address =
        data['address'] ??
            'No Address';

    double total =
        parseToDouble(
          data['total'],
        );

    double shipping =
        parseToDouble(
          data['shipping'],
        );

    double discount =
        parseToDouble(
          data['discount'],
        );

    Timestamp? orderedAt =
        data['orderedAt'];

    String orderedDate =
        orderedAt != null
            ? DateFormat(
                'MMM dd, yyyy',
              ).format(
                orderedAt.toDate(),
              )
            : '';

    String orderedTime =
        orderedAt != null
            ? DateFormat(
                'hh:mm a',
              ).format(
                orderedAt.toDate(),
              )
            : '';

    String orderId =
        order.id.length >= 6
            ? order.id.substring(
                0,
                6,
              )
            : order.id;

    double subtotal = 0;

    for (var item in items) {

      double price =
          parseToDouble(
            item['price'],
          );

      int quantity =
          parseToInt(
            item['quantity'],
          );

      subtotal +=
          (price * quantity);
    }

    // Older orders created before the discount field was saved
    // can still recover the original discount from:
    // subtotal + shipping - total.
    if (!data.containsKey('discount')) {
      final inferredDiscount =
          subtotal + shipping - total;

      discount =
          inferredDiscount > 0
              ? inferredDiscount
              : 0;
    }

    return Scaffold(

      backgroundColor:
          const Color(
        0xFF05070D,
      ),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            const Color(
          0xFF05070D,
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(

          "Order Details",

          style: TextStyle(

            color:
                Colors.white,

            fontSize: 24,

            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            onPressed: () async {

  await Printing.layoutPdf(

    onLayout: (format) async {

      final pdf = pw.Document();

      // Use a Latin font as the primary font and Noto Sans Arabic
      // as a fallback. This keeps English/Latin characters working
      // while also supporting Arabic characters in the same PDF.
      final latinFont =
          await PdfGoogleFonts.robotoRegular();

      final latinBoldFont =
          await PdfGoogleFonts.robotoBold();

      final arabicFont =
          await PdfGoogleFonts.notoSansArabicRegular();

      final arabicBoldFont =
          await PdfGoogleFonts.notoSansArabicBold();

      final image = await imageFromAssetBundle(
        'assets/1.png',
      );

      pdf.addPage(

        pw.MultiPage(

          pageFormat: PdfPageFormat.a4,

          theme: pw.ThemeData.withFont(
            base: latinFont,
            bold: latinBoldFont,
            fontFallback: [
              arabicFont,
              arabicBoldFont,
            ],
          ),

          build: (context) => [

            /// TOP IMAGE
            pw.Container(

              height: 180,

              decoration: pw.BoxDecoration(

                borderRadius:
                    pw.BorderRadius.circular(20),

                image: pw.DecorationImage(
                  image: image,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),

            pw.SizedBox(height: 20),

            /// ORDER INFO
            pw.Text(

              "Order ID: $orderId",

              style: pw.TextStyle(

                fontSize: 24,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "$orderedDate • $orderedTime",
            ),

            pw.SizedBox(height: 25),

            /// CUSTOMER INFO
            pw.Text(

              "Customer Information",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Text(
              "Name: $customerName",
            ),

            pw.Text(
              "Phone: $phone",
            ),

            pw.SizedBox(height: 25),

            /// ITEMS
            pw.Text(

              "Order Items",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 15),

            ...items.map((item) {

              double price =
                  double.tryParse(
                        item['price']
                            .toString(),
                      ) ??
                      0;

              int quantity =
                  int.tryParse(
                        item['quantity']
                            .toString(),
                      ) ??
                      1;

              double totalPrice =
                  price * quantity;

              return pw.Container(

                margin:
                    const pw.EdgeInsets.only(
                  bottom: 12,
                ),

                padding:
                    const pw.EdgeInsets.all(12),

                decoration:
                    pw.BoxDecoration(

                  border: pw.Border.all(
                    color: PdfColors.grey300,
                  ),

                  borderRadius:
                      pw.BorderRadius.circular(
                    12,
                  ),
                ),

                child: pw.Row(

                  mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,

                  children: [

                    pw.Column(

                      crossAxisAlignment:
                          pw.CrossAxisAlignment
                              .start,

                      children: [

                        pw.Text(

                          item['name'] ?? '',

                          style: pw.TextStyle(
                            fontWeight:
                                pw.FontWeight
                                    .bold,
                          ),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "Size: ${item['size'] ?? 'N/A'}",
                        ),

                        pw.Text(
                          "$price EGP",
                        ),
                      ],
                    ),

                    pw.Column(

                      crossAxisAlignment:
                          pw.CrossAxisAlignment
                              .end,

                      children: [

                        pw.Text(
                          "x$quantity",
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "$totalPrice EGP",
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 20),

            /// TOTALS
            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Subtotal"),

                pw.Text(
                  "$subtotal EGP",
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Shipping"),

                pw.Text(
                  "$shipping EGP",
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text("Discount"),

                pw.Text(
                  "-$discount EGP",
                ),
              ],
            ),

            pw.Divider(),

            pw.Row(

              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,

              children: [

                pw.Text(

                  "Total Amount",

                  style: pw.TextStyle(
                    fontWeight:
                        pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                pw.Text(

                  "$total EGP",

                  style: pw.TextStyle(
                    fontWeight:
                        pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 25),

            /// ADDRESS
            pw.Text(

              "Shipping Address",

              style: pw.TextStyle(

                fontSize: 20,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                address,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );

      return pdf.save();
    },
  );
},

            icon: const Icon(
              Icons.print_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: ListView(

        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [

          /// TOP BANNER
          Container(

            height: 185,

            decoration:
                BoxDecoration(

              borderRadius:
                  BorderRadius
                      .circular(
                30,
              ),

              image:
                  const DecorationImage(

                image: AssetImage(
                  "assets/1.png",
                ),

                fit: BoxFit.cover,
              ),

              boxShadow: [

                BoxShadow(

                  color: const Color(
                    0xFF6EA6C1,
                  ).withValues(alpha: 
                    0.15,
                  ),

                  blurRadius: 30,

                  spreadRadius: 1,
                ),
              ],

              border: Border.all(

                color: Colors.white
                    .withValues(alpha: 
                  0.06,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          /// ORDER ID
          buildCard(

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Row(

                  children: [

                    Expanded(

                      child: Text(

                        "Order ID: $orderId",

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              22,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    GestureDetector(

                      onTap: () {

                        Clipboard.setData(

                          ClipboardData(
                            text:
                                orderId,
                          ),
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(

                          const SnackBar(

                            content: Text(
                              "Order ID Copied",
                            ),
                          ),
                        );
                      },

                      child:
                          const Icon(

                        Icons
                            .copy_rounded,

                        color:
                            Colors
                                .white54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                Row(

                  children: [

                    const Icon(

                      Icons
                          .calendar_month_rounded,

                      color:
                          Colors
                              .white54,

                      size: 18,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Text(

                      orderedDate,

                      style:
                          const TextStyle(

                        color:
                            Colors
                                .white70,

                        fontSize:
                            15,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                Padding(

                  padding:
                      const EdgeInsets.only(
                    left: 26,
                  ),

                  child: Text(

                    orderedTime,

                    style:
                        const TextStyle(

                      color:
                          Colors
                              .white54,

                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// CUSTOMER INFO
          buildCard(

            child: Column(

              children: [

                Row(

                  children: const [

                    CircleAvatar(

                      radius: 18,

                      backgroundColor:
                          Color(
                        0x226EA6C1,
                      ),

                      child: Icon(

                        Icons.person,

                        color: Color(
                          0xFF6EA6C1,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(

                      "Customer Information",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                Row(

                  children: [

                    CircleAvatar(

                      radius: 34,

                      backgroundColor:
                          Colors
                              .white10,

                      child: Text(

                        customerName
                                .isNotEmpty
                            ? customerName[0]
                                .toUpperCase()
                            : "U",

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              30,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 18,
                    ),

                    Expanded(

                      child: Column(

                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(

                            customerName,

                            style:
                                const TextStyle(

                              color:
                                  Colors
                                      .white,

                              fontSize:
                                  22,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Row(

                            children: [

                              const Icon(

                                Icons.phone,

                                color:
                                    Color(
                                  0xFF6EA6C1,
                                ),

                                size: 18,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Text(

                                phone,

                                style:
                                    const TextStyle(

                                  color:
                                      Colors
                                          .white70,

                                  fontSize:
                                      16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// ORDER ITEMS
          buildCard(

            child: Column(

              children: [

                Row(

                  children: const [

                    CircleAvatar(

                      radius: 18,

                      backgroundColor:
                          Color(
                        0x226EA6C1,
                      ),

                      child: Icon(

                        Icons
                            .shopping_bag_outlined,

                        color: Color(
                          0xFF6EA6C1,
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(

                      "Order Items",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            18,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                ...List.generate(
                  items.length,
                  (index) {

                    var item =
                        items[index];

                    double price =
                        parseToDouble(
                      item['price'],
                    );

                    int quantity =
                        parseToInt(
                      item['quantity'],
                    );

                    double totalPrice =
                        price *
                            quantity;

                    return Container(

                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      padding:
                          const EdgeInsets.all(
                        12,
                      ),

                      decoration:
                          BoxDecoration(

                        borderRadius:
                            BorderRadius
                                .circular(
                          22,
                        ),

                        color: Colors
                            .white
                            .withValues(alpha: 
                          0.03,
                        ),
                      ),

                      child: Row(

                        children: [

                          ClipRRect(

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),

                            child:
                                item['image'] !=
                                            null &&
                                        item['image']
                                            .toString()
                                            .isNotEmpty
                                    ? Image.network(

                                        item['image'],

                                        width:
                                            90,

                                        height:
                                            90,

                                        fit: BoxFit
                                            .cover,
                                      )
                                    : Container(

                                        width:
                                            90,

                                        height:
                                            90,

                                        color: Colors
                                            .white10,

                                        child:
                                            const Icon(
                                          Icons
                                              .image,

                                          color: Colors
                                              .white38,
                                        ),
                                      ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(

                            child: Column(

                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(

                                  item['name'] ??
                                      '',

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white,

                                    fontSize:
                                        19,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(

                                  "Size: ${item['size'] ?? 'N/A'}",

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white60,

                                    fontSize:
                                        15,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(

                                  "${price.toStringAsFixed(0)} EGP",

                                  style:
                                      const TextStyle(

                                    color:
                                        Color(
                                      0xFF6EA6C1,
                                    ),

                                    fontSize:
                                        18,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(

                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,

                            children: [

                              Container(

                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal:
                                      12,
                                  vertical:
                                      8,
                                ),

                                decoration:
                                    BoxDecoration(

                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),

                                  color:
                                      Colors
                                          .white10,
                                ),

                                child: Text(

                                  "x$quantity",

                                  style:
                                      const TextStyle(

                                    color:
                                        Colors
                                            .white,

                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              Text(

                                "${totalPrice.toStringAsFixed(0)} EGP",

                                style:
                                    const TextStyle(

                                  color:
                                      Colors
                                          .white,

                                  fontSize:
                                      18,

                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 8,
                ),

                Divider(
                  color: Colors.white
                      .withValues(alpha: 
                    0.08,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Subtotal",
                  "${subtotal.toStringAsFixed(0)} EGP",
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Shipping",
                  "${shipping.toStringAsFixed(0)} EGP",
                ),

                const SizedBox(
                  height: 10,
                ),

                priceRow(
                  "Discount",
                  "-${discount.toStringAsFixed(0)} EGP",
                  color:
                      const Color(
                    0xFF6EA6C1,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Divider(
                  color: Colors.white
                      .withValues(alpha: 
                    0.08,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Row(

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    const Text(

                      "Total Amount",

                      style:
                          TextStyle(

                        color:
                            Colors
                                .white,

                        fontSize:
                            22,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    Text(

                      "${total.toStringAsFixed(0)} EGP",

                      style:
                          const TextStyle(

                        color:
                            Color(
                          0xFF6EA6C1,
                        ),

                        fontSize:
                            24,

                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          /// ADDRESS
          buildCard(

            child: Row(

              children: [

                const CircleAvatar(

                  radius: 18,

                  backgroundColor:
                      Color(
                    0x226EA6C1,
                  ),

                  child: Icon(

                    Icons.location_on,

                    color: Color(
                      0xFF6EA6C1,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(

                  child: Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Text(

                        "Shipping Address",

                        style:
                            TextStyle(

                          color:
                              Colors
                                  .white,

                          fontSize:
                              18,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(

                        address,

                        style:
                            const TextStyle(

                          color:
                              Colors
                                  .white60,

                          fontSize:
                              16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

/// BUTTONS
Row(

  children: [

    Expanded(

      child: GestureDetector(

        onTap: () {

          callCustomer(phone);
        },

        child: Container(

          height: 62,

          decoration: BoxDecoration(

            borderRadius:
                BorderRadius.circular(20),

            gradient: const LinearGradient(

              colors: [

                Color(0xFFB8D7E5),
                Color(0xFF6EA6C1),
              ],
            ),
          ),

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: const [

              Icon(
                Icons.call_outlined,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(

                "Call The Customer",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),

    const SizedBox(width: 14),

    Expanded(

      child: GestureDetector(

        onTap: () {

          chatCustomer(phone);
        },

        child: Container(

          height: 62,

          decoration: BoxDecoration(

            borderRadius:
                BorderRadius.circular(20),

            gradient: const LinearGradient(

              colors: [

                Color(0xFF32D951),
                Color(0xFF128C28),
              ],
            ),
          ),

          child: Row(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: const [

              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
              ),

              SizedBox(width: 10),

              Text(

                "Chat The Customer",

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

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

const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildCard({
    required Widget child,
  }) {

    return Container(

      padding:
          const EdgeInsets.all(
        18,
      ),

      decoration:
          BoxDecoration(

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        gradient:
            const LinearGradient(

          colors: [

            Color(0xFF111827),
            Color(0xFF0A0F1A),
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        border: Border.all(

          color: Colors.white
              .withValues(alpha: 
            0.05,
          ),
        ),
      ),

      child: child,
    );
  }

  Widget priceRow(
    String title,
    String value, {
    Color color =
        Colors.white70,
  }) {

    return Row(

      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: [

        Text(

          title,

          style: TextStyle(

            color: color,

            fontSize: 17,
          ),
        ),

        Text(

          value,

          style: TextStyle(

            color: color,

            fontSize: 17,

            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }
}