import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:appser/compenents/decoration_authentication.dart';
import 'package:appser/core/auth/auth_error_messages.dart';
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
  static const Color _errorColor = Color(0xFFE57070);

  final _formKey = GlobalKey<FormState>();
  String email1 = '';
  String email2 = '';
  bool loading = false;
  bool _email1Error = false;
  bool _email2Error = false;
  String? _errorMessage;

  late final PasswordRecoveryController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = context.read<PasswordRecoveryController>();
  }

  void _clearError() {
    if (_errorMessage == null && !_email1Error && !_email2Error) return;
    setState(() {
      _email1Error = false;
      _email2Error = false;
      _errorMessage = null;
    });
  }

  Future<void> _recoverPassword() async {
    _clearError();

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _email1Error = !AuthErrorMessages.isValidEmail(email1);
        _email2Error = !AuthErrorMessages.isValidEmail(email2);
        _errorMessage = 'Confira os e-mails informados.';
      });
      return;
    }

    if (email1.trim().toLowerCase() != email2.trim().toLowerCase()) {
      setState(() {
        _email1Error = true;
        _email2Error = true;
        _errorMessage = 'Os e-mails nao coincidem.';
      });
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
      if (!mounted) return;
      final message = AuthErrorMessages.fromException(
        e,
        operation: AuthOperation.passwordRecovery,
      );
      final fields = AuthErrorMessages.fieldsFor(message);
      setState(() {
        _email1Error = fields.email;
        _email2Error = fields.email;
        _errorMessage = message;
      });
    } finally {
      if (mounted && !navigated) {
        setState(() => loading = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!AuthErrorMessages.isValidEmail(value.trim())) {
      return 'E-mail invalido.';
    }
    return null;
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
              TextFormField(
                decoration: getAuthenticationInputDecoration(
                  'E-mail',
                  borderColor:
                      _email1Error ? _errorColor : const Color(0xFFD5D5D5),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email1 = value;
                  if (_email1Error || _errorMessage != null) _clearError();
                },
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: getAuthenticationInputDecoration(
                  'Confirmar e-mail',
                  borderColor:
                      _email2Error ? _errorColor : const Color(0xFFD5D5D5),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  email2 = value;
                  if (_email2Error || _errorMessage != null) _clearError();
                },
                validator: _validateEmail,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.right,
                      maxLines: 4,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: _errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
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
                          'Enviar link de redefinicao',
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
