import 'package:appser/resources/docs/pdf_view.dart';
import 'package:flutter/material.dart';

class MaterialScreenSix extends StatelessWidget {
  const MaterialScreenSix({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 234, 242, 242),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone de voltar à esquerda
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 100, // Ajuste a altura conforme necessário
            ),
            const Text(
              'Sessão 6',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 70, 148, 166),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildMaterialButton(
                    context,
                    title: 'Apostila Ser Sessão 6',
                    icon: Icons.article,
                    onTap: () async {
                      String pdfPath =
                          'docs/materiaisseis/apostilasessaoseis.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfViewerScreen(pdfPath: pdfPath, downloadPath: 'docs/materiaisseis/apostilasessaoseis.docx', pdfTitle: 'Apostila Ser Sessão 6'),
                        ),
                      );
                    },
                  ),
                  _buildMaterialButton(
                    context,
                    title: 'Preencher próxima sessão',
                    icon: Icons.article,
                    onTap: () async {
                      String pdfPath =
                          'docs/materiaisseis/preencherproximaseis.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfViewerScreen(pdfPath: pdfPath, downloadPath: 'docs/materiaisseis/preencherproximaseis.docx', pdfTitle: 'Preencher próxima sessão'),
                        ),
                      );
                    },
                  ),
                  _buildMaterialButton(
                    context,
                    title: 'Apresentação Sessão 6',
                    icon: Icons.article,
                    onTap: () async {
                      String pdfPath =
                          'docs/materiaisseis/apresentacaosessaoseis.pdf'; // Caminho no Firebase Storage

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PdfViewerScreen(pdfPath: pdfPath, downloadPath: 'docs/materiaisseis/apresentacaosessaoseis.pdf', pdfTitle: 'Apresentação Sessão 6'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF00A896)),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline, color: Color(0xFF00A896)),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialButton(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 3,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00A896)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
