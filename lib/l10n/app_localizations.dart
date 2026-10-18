import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BISHE Car Wash'**
  String get appTitle;

  /// No description provided for @customerBooking.
  ///
  /// In en, this message translates to:
  /// **'Car Wash Booking'**
  String get customerBooking;

  /// No description provided for @selectServiceLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Service Location'**
  String get selectServiceLocation;

  /// No description provided for @washingStation.
  ///
  /// In en, this message translates to:
  /// **'Washing Station'**
  String get washingStation;

  /// No description provided for @mobileService.
  ///
  /// In en, this message translates to:
  /// **'Mobile Service (Home Visit)'**
  String get mobileService;

  /// No description provided for @driveToStation.
  ///
  /// In en, this message translates to:
  /// **'Drive to station'**
  String get driveToStation;

  /// No description provided for @washAtHome.
  ///
  /// In en, this message translates to:
  /// **'Wash at your home'**
  String get washAtHome;

  /// No description provided for @vehicleAndContact.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Owner Information'**
  String get vehicleAndContact;

  /// No description provided for @licensePlate.
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get licensePlate;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @vehicleClass.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Category'**
  String get vehicleClass;

  /// No description provided for @typeA.
  ///
  /// In en, this message translates to:
  /// **'Type A - Small (Sedan/Hatchback)'**
  String get typeA;

  /// No description provided for @typeB.
  ///
  /// In en, this message translates to:
  /// **'Type B - Medium (Crossover/SUV)'**
  String get typeB;

  /// No description provided for @typeC.
  ///
  /// In en, this message translates to:
  /// **'Type C - Large (Truck/Van/Minibus)'**
  String get typeC;

  /// No description provided for @selectServicePackages.
  ///
  /// In en, this message translates to:
  /// **'Select Service Packages'**
  String get selectServicePackages;

  /// No description provided for @totalCombinedPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Combined Price'**
  String get totalCombinedPrice;

  /// No description provided for @homeDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Home / Delivery Address'**
  String get homeDeliveryAddress;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @bookStationWash.
  ///
  /// In en, this message translates to:
  /// **'Book Station Wash'**
  String get bookStationWash;

  /// No description provided for @requestMobileDispatch.
  ///
  /// In en, this message translates to:
  /// **'Request Mobile Dispatch'**
  String get requestMobileDispatch;

  /// No description provided for @stationQueue.
  ///
  /// In en, this message translates to:
  /// **'Station Queue'**
  String get stationQueue;

  /// No description provided for @cashierHub.
  ///
  /// In en, this message translates to:
  /// **'Cashier Hub'**
  String get cashierHub;

  /// No description provided for @adminControl.
  ///
  /// In en, this message translates to:
  /// **'Admin Operations & Control Hub'**
  String get adminControl;

  /// No description provided for @liveQueue.
  ///
  /// In en, this message translates to:
  /// **'Live Queue'**
  String get liveQueue;

  /// No description provided for @customerHistory.
  ///
  /// In en, this message translates to:
  /// **'Customer History'**
  String get customerHistory;

  /// No description provided for @financials.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @pricingMatrix.
  ///
  /// In en, this message translates to:
  /// **'Pricing Matrix'**
  String get pricingMatrix;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @registerWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Register Walk-In / Phone Customer'**
  String get registerWalkIn;

  /// No description provided for @releasedCustomers.
  ///
  /// In en, this message translates to:
  /// **'Released Customers & Order History'**
  String get releasedCustomers;

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get verifyPayment;

  /// No description provided for @paidAndVerified.
  ///
  /// In en, this message translates to:
  /// **'Paid & Verified'**
  String get paidAndVerified;

  /// No description provided for @servicePackage.
  ///
  /// In en, this message translates to:
  /// **'Service Package'**
  String get servicePackage;

  /// No description provided for @assignedWasher.
  ///
  /// In en, this message translates to:
  /// **'Assigned Washer'**
  String get assignedWasher;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due'**
  String get amountDue;

  /// No description provided for @suggestedArrival.
  ///
  /// In en, this message translates to:
  /// **'Suggested arrival: Start washing in ~{mins} mins'**
  String suggestedArrival(String mins);

  /// No description provided for @vehiclesAhead.
  ///
  /// In en, this message translates to:
  /// **'vehicle(s) ahead'**
  String get vehiclesAhead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
