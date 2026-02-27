import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:flutter/material.dart';

class PasswordRecoverySentScreen extends StatelessWidget {
  const PasswordRecoverySentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: const AppBackAppBar(titleText: 'Recuperar senha'),
      body: Align(
        alignment: const Alignment(0, -0.35),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Image(
                image: AssetImage('assets/certo.png'),
                height: 80,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 40),
              Text(
                'Enviamos um link para seu e-mail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232323),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'verifique sua caixa de entrada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF232323),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
