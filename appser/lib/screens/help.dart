import 'package:appser/presentation/widgets/app_background.dart';
import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/services/activity_auto_advance_settings_service.dart';
import 'package:flutter/material.dart';

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  static const _dividerCyan = Color(0xFF60BFCD);
  bool _autoAdvanceEnabled = false;
  bool _loadingAutoAdvance = true;

  @override
  void initState() {
    super.initState();
    _loadAutoAdvance();
  }

  Future<void> _loadAutoAdvance() async {
    final enabled = await ActivityAutoAdvanceSettingsService.isEnabled();
    if (!mounted) return;
    setState(() {
      _autoAdvanceEnabled = enabled;
      _loadingAutoAdvance = false;
    });
  }

  Future<void> _setAutoAdvance(bool enabled) async {
    setState(() {
      _autoAdvanceEnabled = enabled;
    });
    await ActivityAutoAdvanceSettingsService.setEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    const faqs = <_FaqItem>[
      _FaqItem(
        question: 'Como faço para acessar as sessões?',
        answer:
            'Abra a aba de Sessões no menu inferior e selecione a sessão desejada.',
      ),
      _FaqItem(
        question: 'Posso pausar e continuar depois?',
        answer:
            'Sim. Você pode pausar e retomar quando quiser. O progresso fica salvo automaticamente.',
      ),
      _FaqItem(
        question: 'O áudio não está tocando. O que faço?',
        answer:
            'Verifique sua conexão com a internet e o volume do aparelho. Se persistir, feche e abra o app novamente.',
      ),
      _FaqItem(
        question: 'Como entrar em contato com suporte?',
        answer: 'Use o e-mail abaixo para falar com a nossa equipe.',
      ),
    ];

    return AppScaffold(
      appBar: const AppBackAppBar(titleText: 'Ajuda'),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Avancar atividades automaticamente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF232323),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quando um audio ou video terminar, o app abre a proxima atividade da mesma sessao. Ao chegar ao fim da sessao, ele nao abre o Material de Apoio.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Color(0xFF232323),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _autoAdvanceEnabled,
                      activeColor: const Color(0xFF2F7888),
                      onChanged: _loadingAutoAdvance ? null : _setAutoAdvance,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Perguntas frequentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF232323),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < faqs.length; i++) ...[
                        ExpansionTile(
                          key: PageStorageKey('faq_$i'),
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          collapsedIconColor: const Color(0xFF2F7888),
                          iconColor: const Color(0xFF2F7888),
                          title: Text(
                            faqs[i].question,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF232323),
                            ),
                          ),
                          children: [
                            Text(
                              faqs[i].answer,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: Color(0xFF232323),
                              ),
                            ),
                          ],
                        ),
                        if (i != faqs.length - 1)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: _dividerCyan,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Não conseguiu a ajuda? Entre em contato conosco.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF232323),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _dividerCyan,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/email.png',
                              width: 22,
                              height: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'biancamr186@gmail.com',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
