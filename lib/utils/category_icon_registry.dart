import 'package:flutter/material.dart';

/// Maps category icon code points stored in Firestore
/// to compile-time constant Material icons.
class CategoryIconRegistry {
  CategoryIconRegistry._();

  static const List<IconData> icons = [
    Icons.category_outlined,
    Icons.checkroom_rounded,
    Icons.medical_services_outlined,
    Icons.medical_information_outlined,
    Icons.construction_rounded,
    Icons.shopping_bag_outlined,
    Icons.sell_outlined,
    Icons.health_and_safety_outlined,
    Icons.science_outlined,
    Icons.workspace_premium_outlined,
    Icons.local_hospital_outlined,
    Icons.brush_outlined,
    Icons.inventory_2_outlined,
    Icons.cleaning_services_outlined,
    Icons.biotech_outlined,
    Icons.assignment_outlined,
  ];

  static IconData resolve(dynamic codePoint) {
    final int value = codePoint is num
        ? codePoint.toInt()
        : Icons.category_outlined.codePoint;

    for (final icon in icons) {
      if (icon.codePoint == value) {
        return icon;
      }
    }

    return Icons.category_outlined;
  }
}
