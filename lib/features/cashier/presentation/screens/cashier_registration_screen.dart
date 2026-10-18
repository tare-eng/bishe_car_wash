import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'package:bishe_car_wash/main.dart';

class CashierRegistrationScreen extends ConsumerStatefulWidget {
  const CashierRegistrationScreen({super.key});

  @override
  ConsumerState<CashierRegistrationScreen> createState() =>
      _CashierRegistrationScreenState();
}

class _CashierRegistrationScreenState
    extends ConsumerState<CashierRegistrationScreen> {
  final _plateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedSource = 'walk_in';
  String _selectedLocation = 'stationary';
  String _selectedCategoryEnum = 'TYPE_A';
  int _selectedBay = 1;
  int? _selectedEmployeeId;
  final Set<int> _selectedServiceIds = {};

  List<Map<String, dynamic>> _washers = [];
  List<Map<String, dynamic>> _allServices = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  int _queueAheadCount = 0;

  RealtimeChannel? _servicesSubscription;

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
    _setupServicesRealtime();
  }

  void _setupServicesRealtime() {
    _servicesSubscription = Supabase.instance.client
        .channel('public:services_cashier_screen_multi')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: (_) => _fetchServicesOnly(),
        )
        .subscribe();
  }

  Future<void> _fetchServicesOnly() async {
    try {
      final servicesRes = await Supabase.instance.client
          .from('services')
          .select()
          .order('id', ascending: true);

      if (!mounted) return;
      setState(() {
        _allServices = List<Map<String, dynamic>>.from(servicesRes);
      });
    } catch (_) {}
  }

  Future<void> _fetchDropdownData() async {
    try {
      final washersRes =
          await Supabase.instance.client.from('employees').select();

      List<Map<String, dynamic>> loadedWashers =
          List<Map<String, dynamic>>.from(washersRes);

      final filteredWashers = loadedWashers
          .where((e) => e['role'] == 'washer' || e['role'] == null)
          .toList();

      _washers = filteredWashers.isNotEmpty ? filteredWashers : loadedWashers;

      if (_washers.isEmpty) {
        _washers = [
          {'id': 1, 'full_name': 'General Washer Staff', 'phone': 'N/A'}
        ];
      }
      _selectedEmployeeId = _washers.first['id'] as int?;

      final servicesRes = await Supabase.instance.client
          .from('services')
          .select()
          .order('id', ascending: true);

      _allServices = List<Map<String, dynamic>>.from(servicesRes);
      if (_filteredServices.isNotEmpty) {
        _selectedServiceIds.add(_filteredServices.first['id'] as int);
      }

      final bookingsRes = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('assigned_bay', _selectedBay)
          .inFilter('status',
              ['order_placed', 'confirmed', 'in_progress', 'washing', 'ready']);

      if (!mounted) return;
      setState(() {
        _queueAheadCount = bookingsRes.length;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
        totalComm += (s['commission_amount'] ?? 100.0).toDouble();
      }
    }
    return totalComm > 0 ? totalComm : 100.0;
  }

  Future<void> _submitRegistration() async {
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
            content: Text('Please enter delivery address for mobile service')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final plate = _plateController.text.trim().toUpperCase();
      final ownerName = _nameController.text.trim().isEmpty
          ? 'Customer'
          : _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Check or insert vehicle
      final existingVehicle = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('license_plate', plate)
          .maybeSingle();

      int vehicleId;
      if (existingVehicle != null) {
        vehicleId = existingVehicle['id'] as int;
      } else {
        final newVehicle = await Supabase.instance.client
            .from('vehicles')
            .insert({
              'license_plate': plate,
              'make_model': 'Customer Vehicle',
              'category': _selectedCategoryEnum,
              'customer_phone': phone,
            })
            .select('id')
            .single();
        vehicleId = newVehicle['id'] as int;
      }

      final int primaryServiceId = _selectedServiceIds.first;
      final currentUser = Supabase.instance.client.auth.currentUser;

      final Map<String, dynamic> bookingPayload = {
        'customer_id': currentUser?.id,
        'vehicle_id': vehicleId,
        'service_id': primaryServiceId,
        'source': _selectedSource,
        'location_type': _selectedLocation,
        'total_amount': _calculatedAmount,
        'commission_earned': _calculatedCommission,
        'owner_name': ownerName,
        'assigned_bay': _selectedLocation == 'stationary' ? _selectedBay : null,
        'employee_id': _selectedEmployeeId,
        'payment_status': 'pending',
        'status': 'order_placed',
      };

      if (_selectedLocation == 'mobile') {
        bookingPayload['delivery_address'] = _addressController.text.trim();
      }

      await Supabase.instance.client.from('bookings').insert(bookingPayload);

      if (!mounted) return;
      Navigator.pop(context, true);

      final int estWaitMins = _queueAheadCount * 45;
      final String successMsg = _selectedSource == 'phone'
          ? 'Phone booking registered! Arrival in ~$estWaitMins mins.'
          : 'Customer registered and added to queue!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text(successMsg),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering booking: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _servicesSubscription?.unsubscribe();
    _plateController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentFilteredServices =
        _filteredServices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Terminal - Customer Intake'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          // Language Switcher (EN & AM for Cashier Terminal)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language_rounded, color: Colors.white),
            tooltip: 'Language / ቋንቋ',
            onSelected: (Locale newLocale) {
              ref.read(localeProvider.notifier).state = newLocale;
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('am'), child: Text('አማርኛ (Amharic)')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car, size: 16),
                              SizedBox(width: 6),
                              Text('Gate Walk-In'),
                            ],
                          ),
                          selected: _selectedSource == 'walk_in',
                          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSource = 'walk_in');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_in_talk, size: 16),
                              SizedBox(width: 6),
                              Text('Phone Call'),
                            ],
                          ),
                          selected: _selectedSource == 'phone',
                          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSource = 'phone');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      labelText: 'Wash Service Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'stationary',
                        child: Text('Washing Station (Bay Washing)'),
                      ),
                      DropdownMenuItem(
                        value: 'mobile',
                        child: Text('Mobile Service (Home Washing)'),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedLocation = val ?? 'stationary'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: 'License Plate Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedLocation == 'mobile') ...[
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Home / Delivery Address *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryEnum,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Class *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'TYPE_A',
                          child: Text('Type A - Small (Sedan/Hatchback)')),
                      DropdownMenuItem(
                          value: 'TYPE_B',
                          child: Text('Type B - Medium (Crossover/SUV)')),
                      DropdownMenuItem(
                          value: 'TYPE_C',
                          child: Text('Type C - Large (Truck/Van/Minibus)')),
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
                  const Text(
                    'Select Service Packages (Multiple Allowed) *',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
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
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'At least one service must be selected.'),
                                    ),
                                  );
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedLocation == 'stationary') ...[
                    DropdownButtonFormField<int>(
                      value: _selectedBay,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Work Bay',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 1, child: Text('Bay 1 (Stationary)')),
                        DropdownMenuItem(
                            value: 2, child: Text('Bay 2 (Stationary)')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedBay = val ?? 1),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<int>(
                    value: _selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Washer Staff *',
                      border: OutlineInputBorder(),
                    ),
                    items: _washers.map((w) {
                      return DropdownMenuItem<int>(
                        value: w['id'] as int,
                        child: Text(
                          '${w['full_name']} (${w['phone'] ?? 'Staff'})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedEmployeeId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_calculatedAmount ETB',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Washer Commission:',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '$_calculatedCommission ETB',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isSubmitting ? null : _submitRegistration,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _selectedSource == 'phone'
                                  ? 'Confirm Phone Booking'
                                  : 'Register & Add to Live Queue',
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
