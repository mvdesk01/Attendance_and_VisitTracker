import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class TitleCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final formatted = text.split(' ').map((word) {
      if (word.isEmpty) return word;

      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
