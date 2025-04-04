import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomTextTheme {
  CustomTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: ColorConstants.neutralDark,
    ),
    headlineMedium: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: ColorConstants.neutralDark,
    ),
    headlineSmall: TextStyle().copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ColorConstants.neutralDark,
    ),

    titleLarge: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: ColorConstants.neutralDark,
    ),
    titleMedium: TextStyle().copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ColorConstants.neutralDark,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: ColorConstants.neutralDark,
    ),

    bodyLarge: TextStyle().copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: ColorConstants.neutralDark,
    ),
    bodyMedium: TextStyle().copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: ColorConstants.neutralDark,
    ),
    bodySmall: TextStyle().copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: ColorConstants.neutralDark,
    ),

    labelLarge: TextStyle().copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ColorConstants.neutralDark,
    ),
    labelMedium: TextStyle().copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: ColorConstants.neutralDark,
    ),
    labelSmall: TextStyle().copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: ColorConstants.neutralDark,
    ),
  );
}
