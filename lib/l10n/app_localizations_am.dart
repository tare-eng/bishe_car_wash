// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ቢሼ የመኪና ማጠቢያ';

  @override
  String get customerBooking => 'የመኪና ማጠቢያ ቀጠሮ';

  @override
  String get selectServiceLocation => 'የአገልግሎት ቦታ ይምረጡ';

  @override
  String get washingStation => 'በጣቢያ (በቦታው)';

  @override
  String get mobileService => 'የሞባይል አገልግሎት (ቤት ድረስ)';

  @override
  String get driveToStation => 'ወደ ጣቢያው ይምጡ';

  @override
  String get washAtHome => 'እቤትዎ ድረስ እናጥባለን';

  @override
  String get vehicleAndContact => 'የመኪናና ባለቤት መረጃ';

  @override
  String get licensePlate => 'ታርጋ ቁጥር';

  @override
  String get fullName => 'ሙሉ ስም';

  @override
  String get phoneNumber => 'ስልክ ቁጥር';

  @override
  String get vehicleClass => 'የመኪና ምድብ';

  @override
  String get typeA => 'ዓይነት ሀ - አነስተኛ (ሴዳን/ሀችባክ)';

  @override
  String get typeB => 'ዓይነት ለ - መካከለኛ (ክሮስኦቨር/ኤስ.ዩ.ቪ)';

  @override
  String get typeC => 'ዓይነት ሐ - ትልቅ (ጭነት/ቫን/ሚኒባስ)';

  @override
  String get selectServicePackages => 'የአገልግሎት ፓኬጆችን ይምረጡ';

  @override
  String get totalCombinedPrice => 'አጠቃላይ ድምር ዋጋ';

  @override
  String get homeDeliveryAddress => 'የቤት / የደረሰኝ አድራሻ';

  @override
  String get gps => 'ጂ.ፒ.ኤስ (GPS)';

  @override
  String get bookStationWash => 'በጣቢያ ለማጠብ ይዘዙ';

  @override
  String get requestMobileDispatch => 'ተንቀሳቃሽ ቡድን ይዘዙ';

  @override
  String get stationQueue => 'የጣቢያው ተራ ተጠባባቂ';

  @override
  String get cashierHub => 'የካሸር መቆጣጠሪያ ጣቢያ';

  @override
  String get adminControl => 'የአድሚን አስተዳደር ማዕከል';

  @override
  String get liveQueue => 'የቀጥታ ተራ';

  @override
  String get customerHistory => 'የደንበኞች ታሪክ';

  @override
  String get financials => 'የገንዘብ ሪፖርት';

  @override
  String get pricingMatrix => 'የዋጋ ዝርዝር';

  @override
  String get employees => 'ሰራተኞች';

  @override
  String get registerWalkIn => 'በአካል / በስልክ የመጣ ደንበኛ መዝግብ';

  @override
  String get releasedCustomers => 'የተለቀቁ ደንበኞች እና ታሪክ';

  @override
  String get verifyPayment => 'ክፍያ አረጋግጥ';

  @override
  String get paidAndVerified => 'ተከፍሎ የተረጋገጠ';

  @override
  String get servicePackage => 'የአገልግሎት ፓኬጅ';

  @override
  String get assignedWasher => 'የተመደበ አጣቢ';

  @override
  String get amountDue => 'የሚከፈል መጠን';

  @override
  String suggestedArrival(String mins) {
    return 'የሚጠበቅበት ሰዓት: በ ~$mins ደቂቃ ውስጥ ይጀመራል';
  }

  @override
  String get vehiclesAhead => 'መኪኖች በቅድመ ተራ ላይ';
}
