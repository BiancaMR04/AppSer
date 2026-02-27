import 'package:appser/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:appser/presentation/widgets/app_back_app_bar.dart';
import 'package:appser/presentation/widgets/app_scaffold.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:flutter/material.dart';

import 'package:appser/core/theme/app_colors.dart';
import 'package:appser/presentation/widgets/app_elevated_row_button.dart';
import 'package:appser/sessions/widgets/session_header.dart';

class SessionMaterialScreen extends StatelessWidget {
  final int sessionNumber;

  const SessionMaterialScreen({super.key, required this.sessionNumber});

  @override
  Widget build(BuildContext context) {
    final items = SessionCatalog.materialItemsFor(sessionNumber);
    final String sessionId = 'sessao_$sessionNumber';

    const dividerColor = Color(0xFF10707E);

    String displayTitle(String raw) {
      return raw.replaceFirst(RegExp(r'^\s*\d+\.\s*'), '').trim();
    }

    return AppScaffold(
      backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBackAppBar(titleText: 'Material de apoio'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SessionHeader(
              title: 'Sessão $sessionNumber',
              titleStyle: _titleStyleForSession(sessionNumber),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1, color: dividerColor),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  pdfPath: item.pdfPath,
                                  downloadPath: item.downloadPath,
                                  pdfTitle: item.pdfTitle,
                                  sessaoId: sessionId,
                                  itemId: item.pdfPath,
                                  isSupplementary: true,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/livro.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    displayTitle(item.title),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  static TextStyle _titleStyleForSession(int sessionNumber) {
    if (sessionNumber == 4) {
      return const TextStyle(
        fontSize: 24,
        color: AppColors.brandTeal,
      );
    }

    return const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryBlue,
    );
  }
}
