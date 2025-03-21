import 'package:flutter/material.dart';

class AppStyles {

  static ButtonStyle customButtonStyle(Color color) {
    return ElevatedButton.styleFrom(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(8),
      backgroundColor: color,
    );
  }

  static BoxDecoration customBoxDecoration(Color color, double radius) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: color,
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          blurStyle: BlurStyle.normal,
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(0, 5),
          spreadRadius: 0,
        )
      ],
    );
  }
}
