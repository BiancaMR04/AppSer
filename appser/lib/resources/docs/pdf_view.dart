import 'package:appser/screens/help.dart';
import 'package:appser/screens/home.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String downloadPath; // Caminho para o download do arquivo (PDF ou DOCX)
  final String pdfTitle;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.downloadPath,
    required this.pdfTitle,
  });

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String localPath = '';
  bool _isPdfViewed = false;

  @override
  void initState() {
    super.initState();
    _downloadPdf(widget.pdfPath);
  }

  Future<void> _downloadPdf(String pdfPath) async {
    try {
      final ref = FirebaseStorage.instance.ref(pdfPath);
      final url = await ref.getDownloadURL();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          localPath = file.path;
        });
      } else {
        throw Exception('Erro no download do PDF');
      }
    } catch (e) {
      print('Erro ao baixar o PDF: $e');
    }
  }

  Future<void> _onPdfViewed() async {
    if (!_isPdfViewed) {
      String userId = "user123"; // Substituir pelo ID do usuário logado
      await FirebaseFirestore.instance
          .collection('progress')
          .doc(userId)
          .update({
        'session3.pdfViewed': true,
      });
      setState(() {
        _isPdfViewed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      //backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
  children: [
    Positioned.fill(
      child: Image.asset(
        'assets/Registrar.png',
        fit: BoxFit.cover,
      ),
    ),
    Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        widget.pdfTitle,
        style: TextStyle(fontSize: 24, color: Colors.teal[600]),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      localPath.isNotEmpty
          ? SizedBox(
              height: 600,
              width: MediaQuery.of(context).size.width * 0.9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PDFView(
                    filePath: localPath,
                    onRender: (_) {
                      _onPdfViewed();
                    },
                  ),
                ),
              ),
            )
          : const CircularProgressIndicator(),
    ],
  ),
),
  ],
      ),
      bottomNavigationBar: Padding(
  
  padding: const EdgeInsets.only(bottom: 20.0), // distância do fundo
  child: SafeArea(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF00A896)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF00A896)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    ),
  ),
),
    );

  
}
}
