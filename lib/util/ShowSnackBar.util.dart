import 'package:flutter/material.dart';

class ShowSnackBar {
  static void showSnackBar (BuildContext context, String content, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar (
        SnackBar (
          content: Text((error ? "Ocurrió un error. Inténtalo de nuevo en unos minutos: " : "") + content),
        )
    );
  }
}