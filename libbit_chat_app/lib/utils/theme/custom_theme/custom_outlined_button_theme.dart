import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomOutlinedButtonTheme {
  CustomOutlinedButtonTheme._();

  static final lightCustomOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: ColorConstants.highlightPrimary,
      side: const BorderSide(color: ColorConstants.highlightPrimary),
      textStyle: const TextStyle(
        fontSize: 12,
        color: ColorConstants.highlightPrimary,
        fontWeight: FontWeight.w600,
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
