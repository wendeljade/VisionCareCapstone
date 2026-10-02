import 'package:flutter/material.dart';

/// Centralized form styling constants to ensure uniformity across the app
class FormThemeConstants {
  // Clinical Color Palette
  static const Color deepNavy = Color(0xFF12343B); // primary/dark elements and headings
  static const Color medicalMint = Color(0xFF63C7B2); // primary accent, buttons, active states
  static const Color softMint = Color(0xFFDDF4EE); // subtle backgrounds and highlights
  static const Color coolOffWhite = Color(0xFFF7FAF9); // main background
  static const Color white = Color(0xFFFFFFFF); // cards and surfaces
  static const Color charcoalNavy = Color(0xFF203238); // primary text
  static const Color slateGray = Color(0xFF68777B); // secondary text
  static const Color paleGrayMint = Color(0xFFDCE8E5); // borders and dividers
  static const Color normalColor = Color(0xFF3E9B78); // normal severity
  static const Color mildColor = Color(0xFFD49A38); // mild severity
  static const Color severeColor = Color(0xFFC95757); // severe severity

  // Backwards compatible aliases
  static const Color primaryBrandColor = medicalMint;
  static const Color backgroundColor = coolOffWhite;
  static const Color surfaceColor = white;
  static const Color borderColor = paleGrayMint;
  static const Color textColor = charcoalNavy;
  static const Color labelColor = slateGray;
  static const Color errorColor = severeColor;

  // Border Radius (clinical, clean)
  static const double borderRadius = 10.0;

  // Spacing
  static const double fieldSpacing = 20.0;
  static const double smallSpacing = 12.0;
  static const double largeSpacing = 28.0;

  // Input Decoration for Text Fields
  static InputDecoration buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: white,
      prefixIcon: Icon(prefixIcon, color: slateGray, size: 20),
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: slateGray,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: slateGray,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: paleGrayMint, width: 1.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: medicalMint, width: 1.8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: severeColor, width: 1.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: severeColor, width: 1.8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
    );
  }

  // Input Decoration for Dropdowns (matches TextFields)
  static InputDecoration buildDropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: white,
      prefixIcon: Icon(prefixIcon, color: slateGray, size: 20),
      labelText: labelText,
      labelStyle: const TextStyle(
        color: slateGray,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: paleGrayMint, width: 1.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: paleGrayMint, width: 1.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: medicalMint, width: 1.8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
    );
  }

  // Text Style for input fields
  static const TextStyle inputTextStyle = TextStyle(
    color: charcoalNavy,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Text Style for labels
  static const TextStyle labelTextStyle = TextStyle(
    color: slateGray,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

/// Validation helper functions
class FormValidators {
  // Validate full name (not empty, min 2 characters)
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    // Only reject numbers and very specific symbols (@#$%^&*(){}[]=+;:<>?/|)
    if (RegExp(r'[0-9@#$%^&*(){}\[\]=+;:<>?/|]').hasMatch(value)) {
      return 'Full name cannot contain numbers or special symbols';
    }
    return null;
  }

  // Validate address (not empty, min 5 characters)
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 5) {
      return 'Address must be at least 5 characters';
    }
    return null;
  }

  // Validate age (between 0 and 150)
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Age must be a valid number';
    }
    if (age < 0 || age > 150) {
      return 'Age must be between 0 and 150';
    }
    return null;
  }

  // Validate birthday (not empty)
  static String? validateBirthday(String? value) {
    if (value == null || value.isEmpty) {
      return 'Birthday is required';
    }
    return null;
  }

  // Validate gender (not empty)
  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  // Validate contact number (phone)
  static String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    if (value.length < 7) {
      return 'Contact number must be at least 7 digits';
    }
    if (value.length > 15) {
      return 'Contact number must not exceed 15 digits';
    }
    // Allow numbers, spaces, hyphens, and plus sign
    if (!RegExp(r'^[\d\s\-+()]+$').hasMatch(value)) {
      return 'Contact number contains invalid characters';
    }
    return null;
  }
}
