import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomFormFieldTheme {
  CustomFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: ColorConstants.neutralMedium,
    suffixIconColor: ColorConstants.neutralMedium,
    labelStyle: const TextStyle().copyWith(
      fontSize: 14,
      color: ColorConstants.neutralMedium,
    ),
    hintStyle: const TextStyle().copyWith(
      fontSize: 14,
      color: ColorConstants.neutralMedium,
    ),
    errorStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal),
    floatingLabelStyle: const TextStyle().copyWith(
      color: ColorConstants.highlightPrimary,
    ),
    border: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        width: 1,
        color: ColorConstants.neutralMedium,
      ),
    ),
    enabledBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        width: 1,
        color: ColorConstants.neutralMedium,
      ),
    ),
    focusedBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        width: 1,
        color: ColorConstants.highlightPrimary,
      ),
    ),
    errorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        width: 1,
        color: ColorConstants.supportError,
      ),
    ),
    focusedErrorBorder: const OutlineInputBorder().copyWith(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        width: 1,
        color: ColorConstants.supportError,
      ),
    ),
  );
}
