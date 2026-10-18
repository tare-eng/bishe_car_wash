// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BISHE Car Wash';

  @override
  String get customerBooking => 'Customer Booking';

  @override
  String get selectServiceLocation => 'Select Service Location';

  @override
  String get washingStation => 'Washing Station';

  @override
  String get mobileService => 'Mobile Service';

  @override
  String get driveToStation => 'Drive to station';

  @override
  String get washAtHome => 'Wash at your home';

  @override
  String get vehicleAndContact => 'Vehicle & Contact Information';

  @override
  String get licensePlate => 'License Plate Number';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get vehicleClass => 'Vehicle Class';

  @override
  String get typeA => 'Type A - Small (Sedan/Hatchback)';

  @override
  String get typeB => 'Type B - Medium (Crossover/SUV)';

  @override
  String get typeC => 'Type C - Large (Truck/Van/Minibus)';

  @override
  String get selectServicePackages =>
      'Select Service Packages (Multiple Allowed)';

  @override
  String get totalCombinedPrice => 'Total Combined Price';

  @override
  String get homeDeliveryAddress => 'Home / Delivery Address';

  @override
  String get gps => 'GPS';

  @override
  String get bookStationWash => 'Book Station Wash';

  @override
  String get requestMobileDispatch => 'Request Mobile Dispatch';

  @override
  String get stationQueue => 'Station Queue';

  @override
  String get cashierHub => 'Cashier Hub';

  @override
  String get adminControl => 'Admin Operations & Control Hub';

  @override
  String get liveQueue => 'Live Queue';

  @override
  String get customerHistory => 'Customer History';

  @override
  String get financials => 'Financials';

  @override
  String get pricingMatrix => 'Pricing Matrix';

  @override
  String get employees => 'Employees';

  @override
  String get registerWalkIn => 'Register Walk-In / Phone Customer';

  @override
  String get releasedCustomers => 'Released Customers & Order History';

  @override
  String get verifyPayment => 'Verify Payment';

  @override
  String get paidAndVerified => 'Paid & Verified';

  @override
  String get servicePackage => 'Service Package';

  @override
  String get assignedWasher => 'Assigned Washer';

  @override
  String get amountDue => 'Amount Due';

  @override
  String suggestedArrival(String mins) {
    return 'Suggested arrival: Start washing in ~$mins mins';
  }

  @override
  String get vehiclesAhead => 'vehicle(s) ahead';
}
