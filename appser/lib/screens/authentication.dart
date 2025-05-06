import 'package:appser/compenents/decoration_authentication.dart';
import 'package:appser/screens/home.dart';
import 'package:appser/services/authetication_service.dart';
import 'package:appser/snackbars/first_snack.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  bool wantEnter = true;
  String? _cpf;
  final _formKey = GlobalKey<FormState>();
  String? _password;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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

    List<int> digits = cpf.split('').map(int.parse).toList();
    int d1 = calcDigit(digits.sublist(0, 9), 10);
    int d2 = calcDigit(digits.sublist(0, 10), 11);
    return d1 == digits[9] && d2 == digits[10];
  }

  final AutheticationService _authService = AutheticationService(FirebaseAuth.instance)
;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 253, 253),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset("assets/logo.png", height: 150),
                  Text(
                    (wantEnter) ? "LOGIN" : "CADASTRO",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 119, 199, 156),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: getAuthenticationInputDecoration("E-mail"),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor, digite seu e-mail";
                      }
                      if (value.length < 6) {
                        return "E-mail inválido";
                      }
                      if (!value.contains("@")) {
                        return "E-mail inválido";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: getAuthenticationInputDecoration("Senha"),
                    obscureText: true,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor, digite sua senha";
                      }
                      if (value.length < 6) {
                        return "A senha precisa twr pelo menos 6 caracteres";
                      }

                      return null;
                    },
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                  Visibility(
                    visible: !wantEnter,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          decoration: getAuthenticationInputDecoration(
                              "Confirmar Senha"),
                          obscureText: true,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Por favor, digite sua senha";
                            }
                            if (!(value.toString() == _password.toString())) {
                              return "As senhas não coincidem";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          controller: _nameController,
                          decoration: getAuthenticationInputDecoration("Nome"),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Por favor, digite seu nome";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          decoration: getAuthenticationInputDecoration("CPF"),
                          keyboardType: TextInputType.number,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return "Por favor, digite seu CPF";
                            }
                            if (!_isValidCPF(value)) {
                              return "CPF inválido";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _cpf = value;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      buttonClick();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF77C79C), // Cor de fundo
                      foregroundColor: const Color(0xFF293738), // Cor do texto
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      (wantEnter) ? "Entrar" : "Registrar",
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        wantEnter = !wantEnter;
                      });
                    },
                    child: Text(
                      (wantEnter)
                          ? "Você não tem cadastro? Crie uma conta aqui!"
                          : "Já tem conta? Entre aqui!",
                      style: const TextStyle(
                        color: Color(0xFF293738),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  buttonClick() {
    String email = _emailController.text;
    String password = _passwordController.text;
    String name = _nameController.text;

    if (_formKey.currentState!.validate()) {
      if (wantEnter) {
        _authService.loginUser(email: email, password: password).then((String? erro) {
  if (erro == null) {
    showSnackBar(context: context, message: "Usuário logado com sucesso!", isError: false);
    print("Usuário autenticado: ${FirebaseAuth.instance.currentUser?.email}");
    setState(() {});

    // 🔄 Força o stream a emitir novamente (ajuda o RouterScreen a reagir)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      print("Novo estado de auth (listen): ${user?.email}");
    });
  


            //RouterScreen().build(context); // Navegue para a tela inicial após o login

            // NÃO navegue, apenas aguarde o Firebase notificar o StreamBuilder
            print(
                "Usuário autenticado: ${FirebaseAuth.instance.currentUser?.email}");
          }
        });
      } else {
        print(
            "${_emailController.text} - ${_passwordController.text} - ${_nameController.text}");
        _authService
            .registerUser(
          email: email,
          password: password,
          name: name,
          cpf: _cpf!,
        )
            .then((String? erro) {
          if (erro == null) {
            showSnackBar(
                context: context,
                message: "Usuário cadastrado com sucesso!",
                isError: false);
          } else {
            showSnackBar(context: context, message: erro);
          }
        });
      }
    }
  }
}


