import 'package:flutter/material.dart';
import 'package:libbit_chat_app/utils/constants/color_constants.dart';

class CustomNavbarTheme {
  CustomNavbarTheme._();

  static final lightCustomNavBarTheme = NavigationBarThemeData(
    height: 80,
    backgroundColor: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.white,
    indicatorColor: Colors.transparent,
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontWeight: FontWeight.w600,
          color: ColorConstants.highlightPrimary,
        ); // Selected state
      }
      return const TextStyle(
        color: ColorConstants.neutralMedium,
      ); // Unselected state
    }), // labelTextStyle
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((state) {
      if (state.contains(WidgetState.selected)) {
        return const IconThemeData(
          color: ColorConstants.highlightPrimary, // Selected icon color
        );
      }
      return const IconThemeData(
        color: ColorConstants.neutralMedium, // Unselected icon color
      );
    }),
  );
}
