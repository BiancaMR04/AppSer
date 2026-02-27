import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appser/compenents/decoration_authentication.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';

import '../presentation/controllers/password_recovery_controller.dart';
import 'password_recovery_sent_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  String email1 = '';
  String email2 = '';
  bool loading = false;

  late final PasswordRecoveryController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = context.read<PasswordRecoveryController>();
  }

  void _recoverPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (email1 != email2) {
      _showSnack("Os e-mails não coincidem");
      return;
    }

    setState(() => loading = true);

    var navigated = false;

    try {
      await _controller.sendPasswordResetEmail(email: email1.trim());
      if (!mounted) return;
      navigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PasswordRecoverySentScreen(),
        ),
      );
    } catch (e) {
      _showSnack("Erro ao enviar e-mail: ${e.toString()}");
    } finally {
      if (mounted && !navigated) {
        setState(() => loading = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.appBackground,
    appBar: const AppBackAppBar(
      titleText: 'Recuperar senha',
    ),
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 80),

            // CAMPO EMAIL
            TextFormField(
              decoration: getAuthenticationInputDecoration('E-mail'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => email1 = value,
              validator: (value) {
                if (value == null || !value.contains("@")) {
                  return "E-mail inválido";
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // CONFIRMAR EMAIL
            TextFormField(
              decoration: getAuthenticationInputDecoration('Confirmar e-mail'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => email2 = value,
              validator: (value) {
                if (value == null || !value.contains("@")) {
                  return "E-mail inválido";
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // BOTÃO
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _recoverPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60BFCD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Enviar link de redefinição",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    ),
  );
}
}
