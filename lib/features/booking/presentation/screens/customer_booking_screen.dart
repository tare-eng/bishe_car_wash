import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'package:bishe_car_wash/main.dart';
import 'package:bishe_car_wash/features/cashier/presentation/screens/cashier_login_screen.dart';
import 'package:bishe_car_wash/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:bishe_car_wash/features/queue/presentation/widgets/shared_queue_tracker_widget.dart';

class CustomerBookingScreen extends ConsumerStatefulWidget {
  const CustomerBookingScreen({super.key});

  @override
  ConsumerState<CustomerBookingScreen> createState() =>
      _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends ConsumerState<CustomerBookingScreen> {
  final _plateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategoryEnum = 'TYPE_A';
  String _selectedLocation = 'stationary';
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  List<Map<String, dynamic>> _allServices = [];
  final Set<int> _selectedServiceIds = {};
  bool _isLoadingServices = true;

  RealtimeChannel? _servicesChannel;

  @override
  void initState() {
    super.initState();
    _fetchAllServices();
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    _servicesChannel = Supabase.instance.client
        .channel('public:services_customer_multi')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: (_) => _fetchAllServices(),
        )
        .subscribe();
  }

  Future<void> _fetchAllServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final res = await Supabase.instance.client
          .from('services')
          .select()
          .order('id', ascending: true);

      if (!mounted) return;
      setState(() {
        _allServices = List<Map<String, dynamic>>.from(res);
        if (_selectedServiceIds.isEmpty && _filteredServices.isNotEmpty) {
          _selectedServiceIds.add(_filteredServices.first['id'] as int);
        }
        _isLoadingServices = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
    }
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _allServices
        .where((s) => s['vehicle_type'] == _selectedCategoryEnum)
        .toList();
  }

  double get _calculatedAmount {
    double total = 0.0;
    for (final s in _filteredServices) {
      if (_selectedServiceIds.contains(s['id'])) {
        final price = _selectedLocation == 'stationary'
            ? (s['stationary_price'] ?? 500.0).toDouble()
            : (s['mobile_price'] ?? 700.0).toDouble();
        total += price;
      }
    }
    return total > 0 ? total : 500.0;
  }

  double get _calculatedCommission {
    double totalComm = 0.0;
    for (final s in _filteredServices) {
      if (_selectedServiceIds.contains(s['id'])) {
        totalComm += (s['commission_amount'] ?? 75.0).toDouble();
      }
    }
    return totalComm > 0 ? totalComm : 75.0;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('GPS is disabled. Opening Location Settings...')),
        );
        await Geolocator.openLocationSettings();
        setState(() => _isFetchingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions were denied.')),
          );
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _addressController.text =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)} (GPS Live)';
        _isFetchingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch GPS location: $e')),
      );
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submitBooking() async {
    if (_plateController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter license plate and phone number')),
      );
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one service package')),
      );
      return;
    }

    if (_selectedLocation == 'mobile' &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your home/delivery address')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final vehicleRes = await Supabase.instance.client
          .from('vehicles')
          .insert({
            'license_plate': _plateController.text.trim().toUpperCase(),
            'make_model': 'Customer Vehicle',
            'category': _selectedCategoryEnum,
            'customer_phone': _phoneController.text.trim(),
          })
          .select()
          .single();

      final int primaryServiceId = _selectedServiceIds.first;

      final Map<String, dynamic> bookingData = {
        'vehicle_id': vehicleRes['id'],
        'service_id': primaryServiceId,
        'source': 'app',
        'location_type': _selectedLocation,
        'total_amount': _calculatedAmount,
        'commission_earned': _calculatedCommission,
        'owner_name': _nameController.text.trim(),
        'payment_status': 'pending',
        'status': 'order_placed',
      };

      if (_selectedLocation == 'mobile') {
        bookingData['delivery_address'] = _addressController.text.trim();
      }

      final bookingRes = await Supabase.instance.client
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      // Save booking ID locally so SharedQueueTrackerWidget locks onto this customer's live position
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('latest_booking_id', bookingRes['id'] as int);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
          content: Text(_selectedLocation == 'stationary'
              ? 'Booking live! Check queue status above for your live arrival details.'
              : 'Mobile unit request submitted! Our team will dispatch to your location.'),
        ),
      );

      _plateController.clear();
      _phoneController.clear();
      _nameController.clear();
      _addressController.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _servicesChannel?.unsubscribe();
    _plateController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> currentFilteredServices =
        _filteredServices;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerBooking),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language_rounded, color: Colors.white),
            tooltip: 'Language / ቋንቋ / Afaan',
            onSelected: (Locale newLocale) {
              ref.read(localeProvider.notifier).state = newLocale;
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('am'), child: Text('አማርኛ (Amharic)')),
              PopupMenuItem(value: Locale('om'), child: Text('Afaan Oromoo')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onSelected: (val) {
              if (val == 'cashier') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CashierLoginScreen()),
                );
              } else if (val == 'admin') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminLoginScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'cashier', child: Text('Cashier Portal')),
              PopupMenuItem(value: 'admin', child: Text('Admin Portal')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedLocation == 'stationary')
              const SharedQueueTrackerWidget(isStaff: false),
            const SizedBox(height: 16),
            Text(
              l10n.selectServiceLocation,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedLocation = 'stationary'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedLocation == 'stationary'
                            ? AppColors.primaryBlue.withOpacity(0.12)
                            : Colors.white,
                        border: Border.all(
                          color: _selectedLocation == 'stationary'
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_car_wash,
                            color: _selectedLocation == 'stationary'
                                ? AppColors.primaryBlue
                                : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.washingStation,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedLocation == 'stationary'
                                  ? AppColors.primaryBlue
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLocation = 'mobile'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedLocation == 'mobile'
                            ? AppColors.primaryBlue.withOpacity(0.12)
                            : Colors.white,
                        border: Border.all(
                          color: _selectedLocation == 'mobile'
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_repair_service,
                            color: _selectedLocation == 'mobile'
                                ? AppColors.primaryBlue
                                : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.mobileService,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedLocation == 'mobile'
                                  ? AppColors.primaryBlue
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.vehicleAndContact,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: '${l10n.licensePlate} *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${l10n.phoneNumber} *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoryEnum,
              decoration: InputDecoration(
                labelText: '${l10n.vehicleClass} *',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'TYPE_A', child: Text(l10n.typeA)),
                DropdownMenuItem(value: 'TYPE_B', child: Text(l10n.typeB)),
                DropdownMenuItem(value: 'TYPE_C', child: Text(l10n.typeC)),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategoryEnum = val;
                    _selectedServiceIds.clear();
                    if (_filteredServices.isNotEmpty) {
                      _selectedServiceIds
                          .add(_filteredServices.first['id'] as int);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectServicePackages,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoadingServices
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentFilteredServices.length,
                      itemBuilder: (context, index) {
                        final s = currentFilteredServices[index];
                        final int serviceId = s['id'] as int;
                        final double sPrice =
                            (s['stationary_price'] ?? 500).toDouble();
                        final double mPrice =
                            (s['mobile_price'] ?? 700).toDouble();
                        final double price =
                            _selectedLocation == 'stationary' ? sPrice : mPrice;
                        final bool isChecked =
                            _selectedServiceIds.contains(serviceId);

                        return CheckboxListTile(
                          title: Text(s['service_name'] ?? 'Wash'),
                          subtitle: Text('$price ETB'),
                          value: isChecked,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedServiceIds.add(serviceId);
                              } else {
                                if (_selectedServiceIds.length > 1) {
                                  _selectedServiceIds.remove(serviceId);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.totalCombinedPrice,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '$_calculatedAmount ETB',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedLocation == 'mobile') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '${l10n.homeDeliveryAddress} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          _isFetchingLocation ? null : _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(l10n.gps),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedLocation == 'stationary'
                            ? '${l10n.bookStationWash} ($_calculatedAmount ETB)'
                            : '${l10n.requestMobileDispatch} ($_calculatedAmount ETB)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
