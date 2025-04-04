import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomAppbarTheme {
  CustomAppbarTheme._();

  static const lightAppBarTheme = AppBarTheme(
    elevation: 0,
    centerTitle: false,
    scrolledUnderElevation: 0,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: ColorConstants.highlightPrimary, size: 24),
    actionsIconTheme: IconThemeData(
      color: ColorConstants.neutralDark,
      size: 24,
    ),
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: ColorConstants.highlightPrimary,
    ),
  );
}
