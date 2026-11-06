// lib/core/app_localizations.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ku'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static AppLocalizations t(BuildContext context) {
    final l = of(context);
    assert(l != null, 'AppLocalizations not found in context');
    return l!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _strings => locale.languageCode == 'ku' ? _ku : _en;

  String get(String key) => _strings[key] ?? _en[key] ?? key;

  // ── Coffee-shop strings ─────────────────────────────────────────────
  String get appTitle => get('appTitle');
  String get appTagline => get('appTagline');

  // Auth
  String get staffConsole => get('staffConsole');
  String get signInToManage => get('signInToManage');
  String get username => get('username');
  String get password => get('password');
  String get signIn => get('signIn');
  String get signOut => get('signOut');
  String get logOut => get('logOut');
  String get logOutConfirm => get('logOutConfirm');
  String get customersDontSignIn => get('customersDontSignIn');
  String get superAdmin => get('superAdmin');
  String get superAdminSubtitle => get('superAdminSubtitle');
  String get invalidCredentials => get('invalidCredentials');
  String get required => get('required');

  // Dashboard
  String get tables => get('tables');
  String get menuManagement => get('menuManagement');
  String get reports => get('reports');
  String get openTables => get('openTables');
  String get ofWord => get('ofWord');
  String get open2 => get('open2');
  String get tableN => get('tableN');
  String get tapToOpen => get('tapToOpen');
  String get waitingDots => get('waitingDots');
  String get newBadge => get('newBadge');
  String get checkBadge => get('checkBadge');
  String get closed => get('closed');
  String get open3 => get('open3');
  String get ordering => get('ordering');
  String get check => get('check');
  String get requestingCheck => get('requestingCheck');
  String get tableWaitingCheck => get('tableWaitingCheck');
  String get tablesWaitingCheck => get('tablesWaitingCheck');

  // Table detail
  String get addItems => get('addItems');
  String get closeTable => get('closeTable');
  String get closeTableConfirm => get('closeTableConfirm');
  String get openTableConfirm => get('openTableConfirm');
  String get qrTable => get('qrTable');
  String get scanQrHint => get('scanQrHint');
  String get done => get('done');
  String get roundN => get('roundN');
  String get total => get('total');
  String get itemSingular => get('itemSingular');
  String get itemPlural => get('itemPlural');
  String get roundSingular => get('roundSingular');
  String get roundPlural => get('roundPlural');
  String get noOrdersYet => get('noOrdersYet');
  String get customerWillPlaceFirstOrder => get('customerWillPlaceFirstOrder');
  String get qrLive => get('qrLive');
  String get customerRequestedCheck => get('customerRequestedCheck');
  String get addItemsForStaffOrder => get('addItemsForStaffOrder');
  String get addToOrder => get('addToOrder');
  String get retry => get('retry');

  // Menu management
  String get addProduct => get('addProduct');
  String get editProduct => get('editProduct');
  String get deleteProductTitle => get('deleteProductTitle');
  String get deleteProductBody => get('deleteProductBody');
  String get name => get('name');
  String get price => get('price');
  String get category => get('category');
  String get description => get('description');
  String get imageUrl => get('imageUrl');
  String get availableForOrdering => get('availableForOrdering');
  String get saveChanges => get('saveChanges');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get noProductsYet => get('noProductsYet');
  String get noProductsYetHint => get('noProductsYetHint');
  String get tapToAddImage => get('tapToAddImage');
  String get imageSelected => get('imageSelected');
  String get saving => get('saving');
  String get errorGeneric => get('errorGeneric');

  // Reports (employee)
  String get daily => get('daily');
  String get weekly => get('weekly');
  String get monthly => get('monthly');
  String get revenue => get('revenue');
  String get closedOrders => get('closedOrders');
  String get avg => get('avg');
  String get noOrdersInPeriod => get('noOrdersInPeriod');

  // Super admin
  String get superAdminReports => get('superAdminReports');
  String get dashboard => get('dashboard');
  String get orders => get('orders');
  String get itemsSold => get('itemsSold');
  String get avgOrder => get('avgOrder');
  String get mostUsedTable => get('mostUsedTable');
  String get topProducts => get('topProducts');
  String get revenuePerHour => get('revenuePerHour');
  String get revenuePerDay => get('revenuePerDay');
  String get tableActivity => get('tableActivity');
  String get noDataForPeriod => get('noDataForPeriod');
  String get noProductsSold => get('noProductsSold');
  String get noSessionsInPeriod => get('noSessionsInPeriod');
  String get stillOpen => get('stillOpen');
  String get openNow => get('openNow');
  String get closedAt => get('closedAt');
  String get minShort => get('minShort');
  String get tablesUsed => get('tablesUsed');
  String get selectYear => get('selectYear');
  String get selectMonth => get('selectMonth');

  // Customer
  String get ourMenu => get('ourMenu');
  String get menuTagline => get('menuTagline');
  String get yourOrder => get('yourOrder');
  String get yourCartIsEmpty => get('yourCartIsEmpty');
  String get cartEmptyAddFirst => get('cartEmptyAddFirst');
  String get placeOrder => get('placeOrder');
  String get each => get('each');
  String get items => get('items');
  String get itemWord => get('itemWord');
  String get add => get('add');
  String get all => get('all');
  String get requestCheck => get('requestCheck');
  String get requestCheckTitle => get('requestCheckTitle');
  String get requestCheckBody => get('requestCheckBody');
  String get orderMore => get('orderMore');
  String get orderMoreItems => get('orderMoreItems');
  String get orderSummary => get('orderSummary');
  String get runningTotal => get('runningTotal');
  String get checkRequestedBanner => get('checkRequestedBanner');
  String get checkRequestedSnack => get('checkRequestedSnack');
  String get noOrdersYetCustomer => get('noOrdersYetCustomer');
  String get orderSomething => get('orderSomething');
  String get somethingWentWrong => get('somethingWentWrong');
  String get retryBtn => get('retryBtn');

  // Scan screen
  String get scanQrTitle => get('scanQrTitle');
  String get pointCameraAtQr => get('pointCameraAtQr');
  String get enterTableManually => get('enterTableManually');
  String get qrWebOnly => get('qrWebOnly');
  String get enterTableNumber => get('enterTableNumber');
  String get invalidQr => get('invalidQr');
  String get invalidTable => get('invalidTable');
  String get tableNClosed => get('tableNClosed');
  String get askStaffOpenTable => get('askStaffOpenTable');
  String get thankYou => get('thankYou');
  String get tableNClosedThankYou => get('tableNClosedThankYou');

  // Common
  String get loading => get('loading');
  String get refresh => get('refresh');
  String get changePassword => get('changePassword');
  String get currentPassword => get('currentPassword');
  String get newPassword => get('newPassword');
  String get confirmNewPassword => get('confirmNewPassword');
  String get updatePassword => get('updatePassword');
  String get passwordUpdated => get('passwordUpdated');
  String get passwordsDoNotMatch => get('passwordsDoNotMatch');
  String get passwordTooShort => get('passwordTooShort');
  String get currentPasswordWrong => get('currentPasswordWrong');

  // Loading messages
  String get loadWarming => get('loadWarming');
  String get loadBrewing => get('loadBrewing');
  String get loadLoadingTables => get('loadLoadingTables');
  String get loadLoadingMenu => get('loadLoadingMenu');
  String get loadLoadingReports => get('loadLoadingReports');
  String get loadLoadingOrder => get('loadLoadingOrder');

  // ── Receipt / printing (NEW) ────────────────────────────────────────
  String get printReceipt => get('printReceipt');
  String get printerSettings => get('printerSettings');
  String get printNow => get('printNow');
  String get changePrinter => get('changePrinter');
  String get forgetSavedPrinter => get('forgetSavedPrinter');
  String get sentToPrinter => get('sentToPrinter');
  String get noPrintersFound => get('noPrintersFound');
  String get selectPrinter => get('selectPrinter');
  String get haveGreatDay => get('haveGreatDay');
}

// ═══════════════════════════════════════════════════════════════════════
// ENGLISH
// ═══════════════════════════════════════════════════════════════════════
const Map<String, String> _en = {
  'appTitle': 'Coffee Shop',
  'appTagline': 'Crafted with care, brewed to order.',

  'staffConsole': 'Staff Console',
  'signInToManage': 'Sign in to manage tables, menu & reports.',
  'username': 'Username',
  'password': 'Password',
  'signIn': 'Sign In',
  'signOut': 'Sign out',
  'logOut': 'Log out',
  'logOutConfirm': 'You will need to sign in again to manage tables.',
  'customersDontSignIn': 'Customers do not need to sign in.',
  'superAdmin': 'Super Admin',
  'superAdminSubtitle': 'Reports, revenue & analytics',
  'invalidCredentials': 'Invalid username or password.',
  'required': 'Required',

  'tables': 'Tables',
  'menuManagement': 'Menu Management',
  'reports': 'Reports',
  'openTables': 'open',
  'ofWord': 'of',
  'open2': 'open',
  'tableN': 'Table',
  'tapToOpen': 'Tap to open',
  'waitingDots': 'Waiting...',
  'newBadge': 'NEW',
  'checkBadge': 'CHECK',
  'closed': 'CLOSED',
  'open3': 'OPEN',
  'ordering': 'ORDERING',
  'check': 'CHECK',
  'requestingCheck': 'Requesting check…',
  'tableWaitingCheck': '1 table is waiting for the check.',
  'tablesWaitingCheck': 'tables are waiting for the check.',

  'addItems': 'Add Items',
  'closeTable': 'Close Table',
  'closeTableConfirm': 'Table will be freed and the QR disabled.',
  'openTableConfirm':
      'This activates the QR code on the table so the customer can scan it, '
          'browse the menu, and place orders.',
  'qrTable': 'QR — Table',
  'scanQrHint': 'Point the customer at this QR to open the menu.',
  'done': 'Done',
  'roundN': 'ROUND',
  'total': 'TOTAL',
  'itemSingular': 'item',
  'itemPlural': 'items',
  'roundSingular': 'round',
  'roundPlural': 'rounds',
  'noOrdersYet': 'No orders yet',
  'customerWillPlaceFirstOrder':
      'The customer will place their first order from the QR menu.',
  'qrLive': 'QR is live. Customer can order.',
  'customerRequestedCheck': 'Customer requested the check — bring the bill.',
  'addItemsForStaffOrder': 'Add items for staff order',
  'addToOrder': 'Add to Order',
  'retry': 'Retry',

  'addProduct': 'Add Product',
  'editProduct': 'Edit Product',
  'deleteProductTitle': 'Delete product?',
  'deleteProductBody': 'This cannot be undone.',
  'name': 'Name',
  'price': 'Price',
  'category': 'Category',
  'description': 'Description',
  'imageUrl': 'Image URL (optional)',
  'availableForOrdering': 'Available for ordering',
  'saveChanges': 'Save Changes',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'noProductsYet': 'No products yet',
  'noProductsYetHint': 'Tap + to add your first item.',
  'tapToAddImage': 'Tap to add image',
  'imageSelected': 'Image selected',
  'saving': 'Saving…',
  'errorGeneric': 'Something went wrong',

  'daily': 'Daily',
  'weekly': 'Weekly',
  'monthly': 'Monthly',
  'revenue': 'Revenue',
  'closedOrders': 'Closed Orders',
  'avg': 'Avg',
  'noOrdersInPeriod': 'No orders in this period',

  'superAdminReports': 'Super Admin Reports',
  'dashboard': 'Dashboard',
  'orders': 'Orders',
  'itemsSold': 'Items Sold',
  'avgOrder': 'Avg Order',
  'mostUsedTable': 'Most-used table',
  'topProducts': 'Top products',
  'revenuePerHour': 'Revenue per hour',
  'revenuePerDay': 'Revenue per day',
  'tableActivity': 'Table activity',
  'noDataForPeriod': 'No data for this period.',
  'noProductsSold': 'No products sold in this range.',
  'noSessionsInPeriod': 'No sessions opened in this period.',
  'stillOpen': 'still open',
  'openNow': 'open now',
  'closedAt': 'closed',
  'minShort': 'min',
  'tablesUsed': 'tables used',
  'selectYear': 'Select year',
  'selectMonth': 'Select month',

  'ourMenu': 'Our Menu',
  'menuTagline': 'Crafted with care, brewed to order.',
  'yourOrder': 'Your Order',
  'yourCartIsEmpty': 'Your cart is empty',
  'cartEmptyAddFirst': 'Add something first!',
  'placeOrder': 'Place Order',
  'each': 'each',
  'items': 'items',
  'itemWord': 'item',
  'add': 'Add',
  'all': 'All',
  'requestCheck': 'Request check',
  'requestCheckTitle': 'Request the check?',
  'requestCheckBody':
      'A staff member will bring your bill. You can still order more until '
          'they close the table.',
  'orderMore': 'Order more',
  'orderMoreItems': 'Order more items',
  'orderSummary': 'Order summary',
  'runningTotal': 'Running total',
  'checkRequestedBanner':
      'Check requested — a staff member is on the way. You can still order more.',
  'checkRequestedSnack':
      'Staff notified — someone will bring your check shortly.',
  'noOrdersYetCustomer': 'No orders yet',
  'orderSomething': 'Order something',
  'somethingWentWrong': 'Something went wrong',
  'retryBtn': 'Retry',

  'scanQrTitle': 'Scan the QR on your table',
  'pointCameraAtQr': 'Point your camera at the QR code on your table.',
  'enterTableManually': 'Enter table number manually',
  'qrWebOnly':
      'QR scanning is available on mobile only.\nUse the link on your table '
          'or enter the table number below.',
  'enterTableNumber': 'Enter table number',
  'invalidQr': 'Invalid QR code.',
  'invalidTable': 'Invalid table number.',
  'tableNClosed': 'Table is closed',
  'askStaffOpenTable':
      'Please ask a member of staff to open this table for you.',
  'thankYou': 'Thank you!',
  'tableNClosedThankYou': 'has been closed. Have a great day!',

  'loading': 'Loading…',
  'refresh': 'Refresh',
  'changePassword': 'Change Password',
  'currentPassword': 'Current password',
  'newPassword': 'New password',
  'confirmNewPassword': 'Confirm new password',
  'updatePassword': 'Update Password',
  'passwordUpdated': 'Password updated.',
  'passwordsDoNotMatch': 'Passwords do not match',
  'passwordTooShort': 'At least 6 characters',
  'currentPasswordWrong': 'Current password is incorrect.',

  'loadWarming': 'Warming up the espresso machine...',
  'loadBrewing': 'Brewing the menu...',
  'loadLoadingTables': 'Loading tables...',
  'loadLoadingMenu': 'Loading menu...',
  'loadLoadingReports': 'Loading reports...',
  'loadLoadingOrder': 'Loading your order...',

  // Receipt / printing
  'printReceipt': 'Print Receipt',
  'printerSettings': 'Printer settings',
  'printNow': 'Print now',
  'changePrinter': 'Change POS printer',
  'forgetSavedPrinter': 'Forget saved printer',
  'sentToPrinter': 'Sent to POS printer.',
  'noPrintersFound': 'No printers found.',
  'selectPrinter': 'Select POS printer',
  'haveGreatDay': 'Have a great day!',
};

// ═══════════════════════════════════════════════════════════════════════
// KURDISH (BADINI)
// ═══════════════════════════════════════════════════════════════════════
const Map<String, String> _ku = {
  'appTitle': 'قەهوەخانە',
  'appTagline': 'ب چاڤڕەغەز و ب دەست هاتیە دروستکرن.',

  'staffConsole': 'پانێلا کارمەندان',
  'signInToManage': 'بچۆ ژوور بۆ ڕێڤەبرنا مێز و مێنووی و ڕاپۆرتان.',
  'username': 'ناڤێ بکارئینەری',
  'password': 'پاسوۆرد',
  'signIn': 'چوونا ژوور',
  'signOut': 'دەرچوون',
  'logOut': 'دەرچوون',
  'logOutConfirm': 'دێ پێدڤی بیت دووبارە بچیی ژوور بۆ ڕێڤەبرنا مێزان.',
  'customersDontSignIn': 'کڕیار پێدڤی ب چوونا ژوور نینن.',
  'superAdmin': 'سەرپەرشتیارێ گشتی',
  'superAdminSubtitle': 'ڕاپۆرت و داهات و شیکاری',
  'invalidCredentials': 'ناڤێ بکارئینەری یان پاسوۆرد خەلەتە.',
  'required': 'پێدڤی یە',

  'tables': 'مێز',
  'menuManagement': 'ڕێڤەبرنا مێنووی',
  'reports': 'ڕاپۆرت',
  'openTables': 'ڤەکرنە',
  'ofWord': 'ژ',
  'open2': 'ڤەکرنە',
  'tableN': 'مێز',
  'tapToOpen': 'کلیک بکە بۆ ڤەکرنێ',
  'waitingDots': 'چاڤەڕێ…',
  'newBadge': 'نوی',
  'checkBadge': 'حیساب',
  'closed': 'گرتی',
  'open3': 'ڤەکرنە',
  'ordering': 'دەستپێکر',
  'check': 'حیساب',
  'requestingCheck': 'داخوازا حیسابی…',
  'tableWaitingCheck': '١ مێز چاڤەڕێیا حیسابی دکەت.',
  'tablesWaitingCheck': 'مێز چاڤەڕێیا حیسابی دکەن.',

  'addItems': 'زێدەکرنا بەرهەمان',
  'closeTable': 'گرتنا مێزێ',
  'closeTableConfirm': 'مێز دێ ڤالا بیت و QR دێ نەچالاک بیت.',
  'openTableConfirm':
      'ئەڤ کارە QR یا سەر مێزێ چالاک دکەت دا کو کڕیار بشیێت سکان بکەت و '
          'مێنووی ببینیت و داخوازی بکەت.',
  'qrTable': 'QR — مێز',
  'scanQrHint': 'کڕیار ئاراستەی ڤی QR بکە دا مێنووی ڤەبیت.',
  'done': 'تەمام',
  'roundN': 'خولی',
  'total': 'کۆم',
  'itemSingular': 'بەرهەم',
  'itemPlural': 'بەرهەم',
  'roundSingular': 'خول',
  'roundPlural': 'خول',
  'noOrdersYet': 'هێشتا چ داخوازی نینن',
  'customerWillPlaceFirstOrder':
      'کڕیار دێ یەکەم داخوازیا خوە ژ مێنووی QR بکەت.',
  'qrLive': 'QR چالاکە. کڕیار دشێت داخوازی بکەت.',
  'customerRequestedCheck': 'کڕیار داخوازا حیسابی کریە — حیساب بینە.',
  'addItemsForStaffOrder': 'زێدەکرنا بەرهەمان بۆ داخوازیا کارمەندی',
  'addToOrder': 'زێدەکرن بۆ داخوازیێ',
  'retry': 'دووبارە هەوڵبدە',

  'addProduct': 'زێدەکرنا بەرهەمی',
  'editProduct': 'دەستکاریکرنا بەرهەمی',
  'deleteProductTitle': 'بەرهەم بهێتە ژێبرن؟',
  'deleteProductBody': 'ئەڤ کارە نەشێت ڤەگەڕینیت.',
  'name': 'ناڤ',
  'price': 'نرخ',
  'category': 'پۆل',
  'description': 'وەسف',
  'imageUrl': 'لینکا وێنەی (ئارەزوومەندانە)',
  'availableForOrdering': 'بەردەستە بۆ داخوازیێ',
  'saveChanges': 'پارێزتنا گوهۆڕینان',
  'cancel': 'هەلوەشاندن',
  'delete': 'ژێبرن',
  'noProductsYet': 'هێشتا چ بەرهەم نینن',
  'noProductsYetHint': 'کلیک ل + بکە بۆ زێدەکرنا یەکەم بەرهەمی.',
  'tapToAddImage': 'کلیک بکە بۆ زێدەکرنا وێنەی',
  'imageSelected': 'وێنە هاتە هەلبژاردن',
  'saving': 'دێتە پارێزتن…',
  'errorGeneric': 'خەلەتیەک ڕویدا',

  'daily': 'ڕۆژانە',
  'weekly': 'هەفتیانە',
  'monthly': 'هەیڤانە',
  'revenue': 'داهات',
  'closedOrders': 'داخوازیێن گرتی',
  'avg': 'ناڤنجی',
  'noOrdersInPeriod': 'چ داخوازی د ڤێ مەودایێ دا نینن',

  'superAdminReports': 'ڕاپۆرتێن سەرپەرشتیارێ گشتی',
  'dashboard': 'داشبۆرد',
  'orders': 'داخوازی',
  'itemsSold': 'بەرهەمێن هاتینە فروتن',
  'avgOrder': 'ناڤنجی داخوازیێ',
  'mostUsedTable': 'مێزا هەرە زێدە بکارهاتی',
  'topProducts': 'بەرهەمێن سەرێ',
  'revenuePerHour': 'داهات ب هەر دەمژمێرەکێ',
  'revenuePerDay': 'داهات ب هەر ڕۆژەکێ',
  'tableActivity': 'چالاکیا مێزان',
  'noDataForPeriod': 'چ داتا د ڤێ مەودایێ دا نینن.',
  'noProductsSold': 'چ بەرهەم د ڤێ مەودایێ دا نەهاتینە فروتن.',
  'noSessionsInPeriod': 'چ دانیشتن د ڤێ مەودایێ دا نەهاتینە ڤەکرن.',
  'stillOpen': 'هێشتا ڤەکرنە',
  'openNow': 'نوکە ڤەکرنە',
  'closedAt': 'گرتی ل',
  'minShort': 'خولەک',
  'tablesUsed': 'مێز هاتینە بکارئینان',
  'selectYear': 'سالێ هەلبژێرە',
  'selectMonth': 'هەیڤێ هەلبژێرە',

  'ourMenu': 'مێنووی مە',
  'menuTagline': 'ب چاڤڕەغەز و ب دەست هاتیە دروستکرن.',
  'yourOrder': 'داخوازیا تە',
  'yourCartIsEmpty': 'سەبەتا تە ڤالایە',
  'cartEmptyAddFirst': 'پێشی چ بەرهەمەکی زێدە بکە!',
  'placeOrder': 'داخوازیێ بکە',
  'each': 'هەر یەک',
  'items': 'بەرهەم',
  'itemWord': 'بەرهەم',
  'add': 'زێدەکرن',
  'all': 'هەمی',
  'requestCheck': 'داخوازا حیسابی',
  'requestCheckTitle': 'داخوازا حیسابی بکە؟',
  'requestCheckBody':
      'کارمەندەک دێ حیسابا تە بینیت. تو دشێی هێشتا زێدەتر داخوازی بکەی '
          'هەتا مێز ناهێتە گرتن.',
  'orderMore': 'زێدەتر داخوازی',
  'orderMoreItems': 'زێدەتر بەرهەم داخوازی بکە',
  'orderSummary': 'کورتەیا داخوازیێ',
  'runningTotal': 'کۆما نها',
  'checkRequestedBanner':
      'حیساب هاتە داخوازکرن — کارمەندەک دێ. تو دشێی هێشتا زێدەتر داخوازی بکەی.',
  'checkRequestedSnack': 'کارمەند هاتە ئاگەهدارکرن — دێ حیسابا تە بینن.',
  'noOrdersYetCustomer': 'هێشتا چ داخوازی نینن',
  'orderSomething': 'چ بەرهەمەکی داخوازی بکە',
  'somethingWentWrong': 'خەلەتیەک ڕویدا',
  'retryBtn': 'دووبارە هەوڵبدە',

  'scanQrTitle': 'QR یا سەر مێزێ سکان بکە',
  'pointCameraAtQr': 'کامێرا خوە ئاراستەی QR یا سەر مێزێ بکە.',
  'enterTableManually': 'ژمارا مێزێ ب دەست بنڤیسە',
  'qrWebOnly':
      'سکانکرنا QR بتنێ ل سەر مۆبایلی کاردکەت.\nلینکا سەر مێزێ بکاربینە '
          'یان ژمارا مێزێ بنڤیسە.',
  'enterTableNumber': 'ژمارا مێزێ بنڤیسە',
  'invalidQr': 'QR یا نەدروست.',
  'invalidTable': 'ژمارا مێزێ نەدروست.',
  'tableNClosed': 'مێز گرتییە',
  'askStaffOpenTable': 'تکایە ژ کارمەندەکی بپارسە ڤێ مێزێ ڤەکەت.',
  'thankYou': 'سپاس!',
  'tableNClosedThankYou': 'هاتە گرتن. ڕۆژەکا خۆش!',

  'loading': 'دێتە هەڵگرتن…',
  'refresh': 'نویکرن',
  'changePassword': 'گوهۆڕینا پاسوۆردی',
  'currentPassword': 'پاسوۆردا نها',
  'newPassword': 'پاسوۆردا نوی',
  'confirmNewPassword': 'پشتڕاستکرنا پاسوۆردا نوی',
  'updatePassword': 'نویکرنا پاسوۆردی',
  'passwordUpdated': 'پاسوۆرد هاتە نویکرن.',
  'passwordsDoNotMatch': 'پاسوۆرد ناگونجان',
  'passwordTooShort': 'کێمترین ٦ پیت',
  'currentPasswordWrong': 'پاسوۆردا نها خەلەتە.',

  'loadWarming': 'ئامادەکرنا مەکینەیا قەهوەی...',
  'loadBrewing': 'ئامادەکرنا مێنووی...',
  'loadLoadingTables': 'هەڵگرتنا مێزان...',
  'loadLoadingMenu': 'هەڵگرتنا مێنووی...',
  'loadLoadingReports': 'هەڵگرتنا ڕاپۆرتان...',
  'loadLoadingOrder': 'هەڵگرتنا داخوازیا تە...',

  // Receipt / printing
  'printReceipt': 'چاپکرنا پسولێ',
  'printerSettings': 'ڕێکخستنێن چاپکەرێ',
  'printNow': 'نوکە چاپ بکە',
  'changePrinter': 'گوهۆڕینا چاپکەرێ POS',
  'forgetSavedPrinter': 'ژێبرنا چاپکەرێ تۆمارکری',
  'sentToPrinter': 'هاتە هنارتن بۆ چاپکەرێ POS.',
  'noPrintersFound': 'چ چاپکەر نەهاتنە دیتن.',
  'selectPrinter': 'چاپکەرێ POS هەلبژێرە',
  'haveGreatDay': 'ڕۆژەکا خۆش!',
};
