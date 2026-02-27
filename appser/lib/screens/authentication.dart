import 'dart:async';

import 'package:appser/compenents/decoration_authentication.dart';
import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/services/resetpassword.dart';
import 'package:appser/snackbars/first_snack.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/controllers/auth_controller.dart';
import '../presentation/controllers/auth_state_controller.dart';
import 'register.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  bool _rememberUser = false;

  static const Color _loginErrorColor = Color(0xFFE57070);
  String? _loginErrorMessage;
  bool _emailLoginError = false;
  bool _passwordLoginError = false;

  void _clearLoginError() {
    if (_loginErrorMessage == null && !_emailLoginError && !_passwordLoginError) {
      return;
    }
    setState(() {
      _loginErrorMessage = null;
      _emailLoginError = false;
      _passwordLoginError = false;
    });
  }

  StreamSubscription<User?>? _authStateSubscription;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AuthController _authController;

  static const _prefsRememberUserKey = 'auth_remember_user';
  static const _prefsRememberEmailKey = 'auth_remember_email';

  @override
  void initState() {
    super.initState();
    unawaited(_loadRememberedUser());

    _emailController.addListener(() {
      if (_emailLoginError || _loginErrorMessage != null) _clearLoginError();
    });
    _passwordController.addListener(() {
      if (_passwordLoginError || _loginErrorMessage != null) _clearLoginError();
    });
  }

  void _setLoginError(String message) {
    final lower = message.toLowerCase();
    bool emailError = false;
    bool passwordError = false;
    String friendly;

    if (lower.contains('senha')) {
      passwordError = true;
      friendly = 'Senha errada, tente novamente!';
    } else if (lower.contains('e-mail') || lower.contains('email')) {
      emailError = true;
      friendly = 'E-mail errado, tente novamente!';
    } else if (lower.contains('usuário') || lower.contains('usuario')) {
      emailError = true;
      friendly = 'E-mail errado, tente novamente!';
    } else {
      // Se não conseguimos identificar, destacamos ambos para o usuário conferir.
      emailError = true;
      passwordError = true;
      friendly = 'E-mail e senha errados, tente novamente!';
    }

    setState(() {
      _loginErrorMessage = friendly;
      _emailLoginError = emailError;
      _passwordLoginError = passwordError;
    });
  }

  bool _validateLoginInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool emailError = false;
    bool passwordError = false;
    String? message;

    if (email.isEmpty || !email.contains('@')) {
      emailError = true;
    }

    if (password.isEmpty || password.length < 6) {
      passwordError = true;
    }

    if (emailError && passwordError) {
      message = 'E-mail e senha errados, tente novamente!';
    } else if (emailError) {
      message = 'E-mail errado, tente novamente!';
    } else if (passwordError) {
      message = 'Senha errada, tente novamente!';
    }

    if (message == null) {
      _clearLoginError();
      return true;
    }

    setState(() {
      _loginErrorMessage = message;
      _emailLoginError = emailError;
      _passwordLoginError = passwordError;
    });
    return false;
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_prefsRememberUserKey) ?? false;
    final email = prefs.getString(_prefsRememberEmailKey) ?? '';

    if (!mounted) return;
    setState(() {
      _rememberUser = remember;
      if (remember && email.isNotEmpty) {
        _emailController.text = email;
      }
    });
  }

  Future<void> _persistRememberedUser({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsRememberUserKey, _rememberUser);
    if (_rememberUser) {
      await prefs.setString(_prefsRememberEmailKey, email);
    } else {
      await prefs.remove(_prefsRememberEmailKey);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authController = context.read<AuthController>();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.appBackground,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

                // LOGO
                Center(
                  child: Image.asset(
                    "assets/logo.png",
                    height: 170,
                  ),
                ),

                const SizedBox(height: 40),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  decoration: getAuthenticationInputDecoration(
                    "E-mail",
                    borderColor:
                        _emailLoginError ? _loginErrorColor : const Color(0xFFD5D5D5),
                  ),
                  style: TextStyle(
                    color: _emailLoginError ? _loginErrorColor : const Color(0xFF232323),
                  ),
                ),

                const SizedBox(height: 20),

                // SENHA
                TextFormField(
                  controller: _passwordController,
                  decoration: getAuthenticationInputDecoration(
                    "Senha",
                    borderColor: _passwordLoginError
                        ? _loginErrorColor
                        : const Color(0xFFD5D5D5),
                  ),
                  obscureText: true,
                  style: TextStyle(
                    color: _passwordLoginError ? _loginErrorColor : const Color(0xFF232323),
                  ),
                ),

              if (_loginErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _loginErrorMessage!,
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: _loginErrorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // LEMBRAR USUÁRIO
                Row(
                  children: [
                    Checkbox(
                      value: _rememberUser,
                      onChanged: (value) {
                        setState(() {
                          _rememberUser = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF60BFCD),
                    ),
                    const Text(
                      "Lembrar usuário",
                      style: TextStyle(
                        color: Color(0xFF232323),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // BOTÃO ENTRAR
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.60,
                    child: ElevatedButton(
                      onPressed: buttonClick,
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
                        "Entrar",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ESQUECI MINHA SENHA
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PasswordRecoveryScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF232323),
                    ),
                    child: const Text("Esqueci minha senha"),
                  ),
                ),

                const SizedBox(height: 50),

                // CRIAR CONTA
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.authLink,
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        color: Color(0xFF232323),
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: 'Você não tem cadastro?\n'),
                        TextSpan(
                          text: 'Crie uma conta aqui',
                          style: TextStyle(
                            color: AppColors.authLink,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  buttonClick() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!_validateLoginInputs()) return;

    // LOGIN
    String? erro = await _authController.login(email: email, password: password);
    if (erro == null) {
      await _persistRememberedUser(email: email);
      showSnackBar(
          context: context,
          message: "Usuário logado com sucesso!",
          isError: false);
      setState(() {});
      final authStateController = context.read<AuthStateController>();
      await _authStateSubscription?.cancel();
      _authStateSubscription =
          authStateController.authStateChanges.listen((user) {
        print("Novo estado de auth (listen): ${user?.email}");
        if (!mounted) return;
        setState(() {});
      });
    } else {
      _setLoginError(erro);
    }
  }
}
