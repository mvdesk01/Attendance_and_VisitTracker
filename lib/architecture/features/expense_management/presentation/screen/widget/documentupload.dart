import 'package:flutter/material.dart';

class DocumentUploadSection extends StatelessWidget {
  final VoidCallback onPickDocument;
  final String? fileName;

  const DocumentUploadSection({
    super.key,
    required this.onPickDocument,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickDocument,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: "Attach Document",
          border: OutlineInputBorder(),
        ),
        child: Text(
          fileName ?? "Select Document",
        ),
      ),
    );
  }
}
