import 'package:flutter/material.dart';

void sendSnackbar(BuildContext context, String message, {Duration duration = const Duration(seconds: 2), Color backgroundColor = const Color.fromARGB(255, 221, 0, 0)}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: backgroundColor,
    ),
  );
}
