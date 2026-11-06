// lib/widgets/language_picker.dart
import 'package:flutter/material.dart';

import '../core/locale_provider.dart';

Future<void> showLanguagePicker(
  BuildContext context,
  LocaleProvider provider,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Language / زمان'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
            title: const Text('English'),
            selected: provider.locale.languageCode == 'en',
            onTap: () {
              provider.setLocale('en');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Text('🏳️', style: TextStyle(fontSize: 22)),
            title: const Text('کوردی (بادینی)'),
            selected: provider.locale.languageCode == 'ku',
            onTap: () {
              provider.setLocale('ku');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel / هەلوەشاندن'),
        ),
      ],
    ),
  );
}
