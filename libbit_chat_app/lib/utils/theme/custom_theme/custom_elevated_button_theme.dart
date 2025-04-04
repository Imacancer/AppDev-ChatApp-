import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomElevatedbuttonTheme {
  CustomElevatedbuttonTheme._();

  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: ColorConstants.highlightPrimary,
      disabledForegroundColor: Colors.white,
      disabledBackgroundColor: ColorConstants.highlightPrimary.withAlpha(100),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      textStyle: TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
