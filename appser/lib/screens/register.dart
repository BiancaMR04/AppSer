import 'package:appser/compenents/decoration_authentication.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../presentation/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _errorColor = Color(0xFFE57070);

  late final AuthController _authController;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _cpfCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  String? _errorMessage;

  bool _nameError = false;
  bool _cpfError = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _confirmPasswordError = false;

  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authController = context.read<AuthController>();
  }

  @override
  void initState() {
    super.initState();

    void clearOnEdit({required TextEditingController controller, required bool Function() isErrored, required void Function() clear}) {
      controller.addListener(() {
        if (!isErrored() && _errorMessage == null) return;
        clear();
      });
    }

    clearOnEdit(
      controller: _nameCtrl,
      isErrored: () => _nameError,
      clear: () {
        if (!mounted) return;
        setState(() {
          _nameError = false;
          _errorMessage = null;
        });
      },
    );

    clearOnEdit(
      controller: _cpfCtrl,
      isErrored: () => _cpfError,
      clear: () {
        if (!mounted) return;
        setState(() {
          _cpfError = false;
          _errorMessage = null;
        });
      },
    );

    clearOnEdit(
      controller: _emailCtrl,
      isErrored: () => _emailError,
      clear: () {
        if (!mounted) return;
        setState(() {
          _emailError = false;
          _errorMessage = null;
        });
      },
    );

    clearOnEdit(
      controller: _passwordCtrl,
      isErrored: () => _passwordError,
      clear: () {
        if (!mounted) return;
        setState(() {
          _passwordError = false;
          _errorMessage = null;
        });
      },
    );

    clearOnEdit(
      controller: _confirmPasswordCtrl,
      isErrored: () => _confirmPasswordError,
      clear: () {
        if (!mounted) return;
        setState(() {
          _confirmPasswordError = false;
          _errorMessage = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    int calcDigit(List<int> numbers, int multiplierStart) {
      int sum = 0;
      for (var i = 0; i < numbers.length; i++) {
        sum += numbers[i] * (multiplierStart - i);
      }
      int mod = sum % 11;
      return (mod < 2) ? 0 : 11 - mod;
    }

    final digits = cpf.split('').map(int.parse).toList();
    final d1 = calcDigit(digits.sublist(0, 9), 10);
    final d2 = calcDigit(digits.sublist(0, 10), 11);
    return d1 == digits[9] && d2 == digits[10];
  }

  void _setError({
    required String message,
    bool name = false,
    bool cpf = false,
    bool email = false,
    bool password = false,
    bool confirmPassword = false,
  }) {
    setState(() {
      _errorMessage = message;
      _nameError = name;
      _cpfError = cpf;
      _emailError = email;
      _passwordError = password;
      _confirmPasswordError = confirmPassword;
    });
  }

  bool _validateInputs() {
    final name = _nameCtrl.text.trim();
    final cpf = _cpfCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (name.isEmpty) {
      _setError(message: 'Informe seu nome.', name: true);
      return false;
    }

    if (cpf.isEmpty || !_isValidCPF(cpf)) {
      _setError(message: 'CPF inválido.', cpf: true);
      return false;
    }

    if (email.isEmpty || !email.contains('@')) {
      _setError(message: 'E-mail inválido.', email: true);
      return false;
    }

    if (password.isEmpty || password.length < 6) {
      _setError(
        message: 'A senha é muito fraca. Use pelo menos 6 caracteres.',
        password: true,
      );
      return false;
    }

    if (confirm != password) {
      _setError(message: 'As senhas não conferem.', confirmPassword: true);
      return false;
    }

    setState(() {
      _errorMessage = null;
      _nameError = false;
      _cpfError = false;
      _emailError = false;
      _passwordError = false;
      _confirmPasswordError = false;
    });

    return true;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    final name = _nameCtrl.text.trim();
    final cpf = _cpfCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    try {
      final erro = await _authController.register(
        email: email,
        password: password,
        name: name,
        cpf: cpf,
      );

      if (!mounted) return;

      if (erro == null) {
        Navigator.of(context).pop();
        return;
      }

      final lower = erro.toLowerCase();
      if (lower.contains('e-mail') || lower.contains('email')) {
        _setError(message: erro, email: true);
      } else if (lower.contains('senha')) {
        _setError(message: erro, password: true);
      } else {
        _setError(message: erro);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 170,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: getAuthenticationInputDecoration(
                      'Nome',
                      borderColor:
                          _nameError ? _errorColor : const Color(0xFFD5D5D5),
                    ),
                    style: TextStyle(
                      color: _nameError ? _errorColor : const Color(0xFF232323),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _cpfCtrl,
                    decoration: getAuthenticationInputDecoration(
                      'CPF',
                      borderColor:
                          _cpfError ? _errorColor : const Color(0xFFD5D5D5),
                    ),
                    style: TextStyle(
                      color: _cpfError ? _errorColor : const Color(0xFF232323),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: getAuthenticationInputDecoration(
                      'E-mail',
                      borderColor:
                          _emailError ? _errorColor : const Color(0xFFD5D5D5),
                    ),
                    style: TextStyle(
                      color: _emailError ? _errorColor : const Color(0xFF232323),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: getAuthenticationInputDecoration(
                      'Senha',
                      borderColor:
                          _passwordError ? _errorColor : const Color(0xFFD5D5D5),
                    ),
                    style: TextStyle(
                      color:
                          _passwordError ? _errorColor : const Color(0xFF232323),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    decoration: getAuthenticationInputDecoration(
                      'Confirmação de senha',
                      borderColor: _confirmPasswordError
                          ? _errorColor
                          : const Color(0xFFD5D5D5),
                    ),
                    style: TextStyle(
                      color: _confirmPasswordError
                          ? _errorColor
                          : const Color(0xFF232323),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
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
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.60,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60BFCD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cadastrar',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.authLink,
                      ),
                      child: const Text(
                        'Já tem cadastro? Entrar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
