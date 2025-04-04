import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_appbar_theme.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_elevated_button_theme.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_form_field_theme.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_outlined_button_theme.dart';
import 'package:libbit_chat_app/utils/theme/custom_theme/custom_text_theme.dart';

class CustomAppTheme {
  CustomAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ColorConstants.highlightPrimary,
    scaffoldBackgroundColor: Colors.white,
    textTheme: CustomTextTheme.lightTextTheme,
    elevatedButtonTheme: CustomElevatedbuttonTheme.lightElevatedButtonTheme,
    appBarTheme: CustomAppbarTheme.lightAppBarTheme,
    inputDecorationTheme: CustomFormFieldTheme.lightInputDecorationTheme,
    outlinedButtonTheme:
        CustomOutlinedButtonTheme.lightCustomOutlinedButtonTheme,
  );
}
