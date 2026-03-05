import 'package:flutter/material.dart';

void showSnackBar({
  required BuildContext context,
  required String message,
  bool isError = true,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);

  // Evita empilhar/"grudar" SnackBars anteriores.
  messenger.clearSnackBars();

  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: isError ? Colors.red : Colors.green,
    duration: duration,
    action: SnackBarAction(
      label: 'OK',
      textColor: Colors.white,
      onPressed: () {
        // Usa o messenger capturado (não depende do context ainda estar ativo).
        messenger.removeCurrentSnackBar();
      },
    ),
  );

  messenger.showSnackBar(snackBar);
}