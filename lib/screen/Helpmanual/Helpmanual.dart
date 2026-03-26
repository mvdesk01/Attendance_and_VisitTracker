import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class HelpManualScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Manual'),
      ),
      body: SfPdfViewer.asset(
        'assets/files/helpmanual.pdf',
      ),
    );
  }
}
