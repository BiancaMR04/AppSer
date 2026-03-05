import 'package:flutter/services.dart';

class CpfUtils {
  static final RegExp _nonDigits = RegExp(r'[^0-9]');

  static String digitsOnly(String value) {
    return value.replaceAll(_nonDigits, '');
  }

  static String format(String value) {
    final digits = digitsOnly(value);
    final capped = digits.length <= 11 ? digits : digits.substring(0, 11);
    return _applyMask(capped);
  }

  static String _applyMask(String digits) {
    if (digits.isEmpty) return '';

    final sb = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      sb.write(digits[i]);

      if (i == 2 && digits.length > 3) sb.write('.');
      if (i == 5 && digits.length > 6) sb.write('.');
      if (i == 8 && digits.length > 9) sb.write('-');
    }
    return sb.toString();
  }
}

/// Mascara CPF automaticamente no formato ###.###.###-##.
///
/// Observação: o valor no controller ficará formatado; use
/// `CpfUtils.digitsOnly(controller.text)` ao salvar.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = CpfUtils.digitsOnly(newValue.text);
    final capped = digits.length <= 11 ? digits : digits.substring(0, 11);
    final masked = CpfUtils.format(capped);

    // Quantos dígitos existiam antes do cursor no texto novo?
    final base = newValue.selection.baseOffset;
    final safeBase = base < 0
        ? 0
        : (base > newValue.text.length ? newValue.text.length : base);
    final digitsBeforeCursor =
        CpfUtils.digitsOnly(newValue.text.substring(0, safeBase)).length;
    final caret = _caretOffsetForDigitCount(digitsBeforeCursor);
    final safeCaret = caret > masked.length ? masked.length : caret;

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: safeCaret),
      composing: TextRange.empty,
    );
  }

  int _caretOffsetForDigitCount(int digitCount) {
    var offset = digitCount;
    if (digitCount > 3) offset += 1; // '.'
    if (digitCount > 6) offset += 1; // '.'
    if (digitCount > 9) offset += 1; // '-'
    return offset;
  }
}
