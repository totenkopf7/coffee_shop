// lib/widgets/money_text.dart
import 'package:flutter/material.dart';

import '../core/config.dart';

/// A [Text] replacement that ALWAYS renders money left-to-right, even
/// inside an RTL paragraph (Kurdish / Arabic). Prevents the classic
/// "000,5" -> "5,000" bidi bug.
class MoneyText extends StatelessWidget {
  final num value;

  /// Optional override for the formatted string (e.g. if you want
  /// "5,000 IQD" without decimals you already have that in AppConfig.money).
  final String? text;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const MoneyText(
    this.value, {
    super.key,
    this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = text ?? AppConfig.money(value);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        content,
        style: style,
        textAlign: textAlign ?? TextAlign.start,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}
