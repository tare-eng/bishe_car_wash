// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appTitle => 'Maanqulqulleessaa BISHE';

  @override
  String get customerBooking => 'Qabduu Tajaajila Maammilaa';

  @override
  String get selectServiceLocation => 'Bakka Qulqullinaa Filadhu';

  @override
  String get washingStation => 'Buufata Dikkoo';

  @override
  String get mobileService => 'Tajaajila Socho\'aa (Manatti)';

  @override
  String get driveToStation => 'Gara buufataatti koottu';

  @override
  String get washAtHome => 'Mana keessanitti isiniif dhiqna';

  @override
  String get vehicleAndContact => 'Odeeffannoo Konkolaataa & Maammilaa';

  @override
  String get licensePlate => 'Lakk. Gabatee Konkolaataa';

  @override
  String get fullName => 'Maqaa Guutuu';

  @override
  String get phoneNumber => 'Lakk. Bilbilaa';

  @override
  String get vehicleClass => 'Gosa Konkolaataa';

  @override
  String get typeA => 'Gosa A - Chixxaa (Sedan/Hatchback)';

  @override
  String get typeB => 'Gosa B - Cidha/Giddu-galeessa (SUV)';

  @override
  String get typeC => 'Gosa C - Guddaa (Minibus/Truck)';

  @override
  String get selectServicePackages =>
      'Paakeejii Tajaajilaa Filadhu (Akkasuma Danuu)';

  @override
  String get totalCombinedPrice => 'Gatii Walii Galaa';

  @override
  String get homeDeliveryAddress => 'Teessoo Manaa / Geessituu';

  @override
  String get gps => 'GPS';

  @override
  String get bookStationWash => 'Buufatatti Qabadhu';

  @override
  String get requestMobileDispatch => 'Tajaajila Socho\'aa Ajajadhu';

  @override
  String get stationQueue => 'Dabare Buufataa';

  @override
  String get cashierHub => 'Kashiiyaarii Hub';

  @override
  String get adminControl => 'Wiirtuu Bulchiinsa Admin';

  @override
  String get liveQueue => 'Dabare Callisaa';

  @override
  String get customerHistory => 'Seenaa Maammiltootaa';

  @override
  String get financials => 'Gabaasa Maallaqaa';

  @override
  String get pricingMatrix => 'Tarree Gatii';

  @override
  String get employees => 'Hojjettoota';

  @override
  String get registerWalkIn => 'Maammila Fuulaa/Bilbilaa Galmeessi';

  @override
  String get releasedCustomers => 'Maammiltoota Gadhiifaman & Seenaa';

  @override
  String get verifyPayment => 'Kaffaltii Mirkaneessi';

  @override
  String get paidAndVerified => 'Kaffalamee Mirkanaa\'e';

  @override
  String get servicePackage => 'Paakeejii Tajaajilaa';

  @override
  String get assignedWasher => 'Hojjetaa Qulqulleessu';

  @override
  String get amountDue => 'Kaffaltii Barbaachisu';

  @override
  String suggestedArrival(String mins) {
    return 'Yeroo tilmaamaa: Daqiiqaa ~$mins keessatti jalqaba';
  }

  @override
  String get vehiclesAhead => 'konkolaatota fuldura jiran';
}
