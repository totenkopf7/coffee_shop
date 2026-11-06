// lib/core/kurdish_material_localizations.dart
import 'package:flutter/material.dart';

class KurdishMaterialLocalizations extends DefaultMaterialLocalizations {
  const KurdishMaterialLocalizations();

  @override
  String get backButtonTooltip => 'ڤەگەر';
  @override
  String get cancelButtonLabel => 'هەلوەشاندن';
  @override
  String get closeButtonTooltip => 'داخستن';
  @override
  String get continueButtonLabel => 'بەردەوامبوون';
  @override
  String get copyButtonLabel => 'کۆپیکرن';
  @override
  String get cutButtonLabel => 'برین';
  @override
  String get deleteButtonTooltip => 'ژێبرن';
  @override
  String get doneButtonLabel => 'تەمام';
  @override
  String get hideAccountsLabel => 'شارتنا هەژماران';
  @override
  String get licensesPageTitle => 'مۆڵەتنامە';
  @override
  String get modalBarrierDismissLabel => 'لابەرن';
  @override
  String get nextMonthTooltip => 'هەیڤا پێشیا';
  @override
  String get nextPageTooltip => 'پەڕەیا پێشیا';
  @override
  String get okButtonLabel => 'باشە';
  @override
  String get openAppDrawerTooltip => 'ڤەکرنا لێستەیێ';
  @override
  String get previousMonthTooltip => 'هەیڤا بۆری';
  @override
  String get previousPageTooltip => 'پەڕەیا بۆری';
  @override
  String get refreshIndicatorSemanticLabel => 'نویکرن';
  @override
  String get searchFieldLabel => 'گەریان';
  @override
  String get selectAllButtonLabel => 'هەمیان هەلبژێرە';
  @override
  String get showAccountsLabel => 'نیشاندانا هەژماران';
  @override
  String get showMenuTooltip => 'نیشاندانا لێستەیێ';
  @override
  String get saveButtonLabel => 'پارێزتن';
  @override
  String get searchFieldTooltip => 'گەریان';
  @override
  String get selectYearSemanticsLabel => 'هەلبژاردنا سالێ';
  @override
  String get timePickerHourModeAnnouncement => 'هەلبژاردنا دەمژمێری';
  @override
  String get timePickerMinuteModeAnnouncement => 'هەلبژاردنا خولەکی';
  @override
  String get viewLicensesButtonLabel => 'دیتنا مۆڵەتنامان';
  @override
  String get datePickerDateOrderString => 'dmy';
  @override
  String get datePickerDateSeparator => '/';
  @override
  String get datePickerDateTimeOrderString => 'date_time';
  @override
  String get datePickerDateTimeSeparator => ' ';

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _KurdishMaterialLocalizationsDelegate();
}

class _KurdishMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _KurdishMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ku';

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const KurdishMaterialLocalizations();

  @override
  bool shouldReload(_KurdishMaterialLocalizationsDelegate old) => false;
}
