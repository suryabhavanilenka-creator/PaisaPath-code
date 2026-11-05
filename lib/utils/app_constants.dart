/// Application-wide constants: categories, payment methods, validation limits
/// and shared string material. One source of truth for the whole app.
library;

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  /// Category display names, in the order used across the UI.
  static const List<String> categories = <String>[
    'Food',
    'Travel',
    'Shopping',
    'Education',
    'Entertainment',
    'Health',
    'Bills',
    'Groceries',
    'Rent',
    'Other',
  ];

  static const List<String> paymentMethods = <String>[
    'Cash',
    'UPI',
    'Debit Card',
    'Credit Card',
    'Bank Transfer',
    'Other',
  ];

  /// Icons shown next to each category. Indexed with [categories].
  static const List<IconData> categoryIcons = <IconData>[
    Icons.restaurant_rounded,          // Food
    Icons.directions_bus_rounded,      // Travel
    Icons.shopping_bag_rounded,        // Shopping
    Icons.school_rounded,              // Education
    Icons.movie_rounded,               // Entertainment
    Icons.medical_services_rounded,    // Health
    Icons.receipt_long_rounded,        // Bills
    Icons.shopping_cart_rounded,       // Groceries
    Icons.home_rounded,                // Rent
    Icons.category_rounded,            // Other
  ];

  /// Accent colours for each category — PaisaPath palette.
  static const List<Color> categoryColors = <Color>[
    Color(0xFFF4B183), // Food      – Warm Coral
    Color(0xFF79C9B1), // Travel    – Soft Teal
    Color(0xFFEC4899), // Shopping
    Color(0xFF8B5CF6), // Education
    Color(0xFFF43F5E), // Entertainment
    Color(0xFF10B981), // Health
    Color(0xFF6366F1), // Bills
    Color(0xFF16A34A), // Groceries
    Color(0xFF40243F), // Rent      – Deep Plum
    Color(0xFF81777D), // Other     – Secondary Text
  ];

  static IconData iconFor(String category) {
    final int index = categories.indexOf(category);
    if (index < 0) return categoryIcons.last;
    return categoryIcons[index];
  }

  static Color colorFor(String category) {
    final int index = categories.indexOf(category);
    if (index < 0) return categoryColors.last;
    return categoryColors[index];
  }

  /// Validation / input limits.
  static const int maxDescriptionLength = 200;
  static const double maxAmount = 99999999;

  /// First date selectable in the date picker.
  static final DateTime firstSelectableDate = DateTime(2000);

  static const String appName = 'PaisaPath';
  static const String appTagline = 'Your Money. Your Path. Your Control.';
  static const String appFullName = 'PaisaPath - Expenses Tracker';
  static const String appVersion = '1.1.0';
}
