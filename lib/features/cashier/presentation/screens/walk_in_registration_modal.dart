import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class WalkInRegistrationModal extends StatefulWidget {
  const WalkInRegistrationModal({super.key});

  @override
  State<WalkInRegistrationModal> createState() =>
      _WalkInRegistrationModalState();
}

class _WalkInRegistrationModalState extends State<WalkInRegistrationModal> {
  final _plateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedSource = 'walk_in';
  String _selectedLocation = 'stationary';
  int _selectedBay = 1;
  int? _selectedEmployeeId;
  int? _selectedServiceId;

  List<Map<String, dynamic>> _washers = [];
  List<Map<String, dynamic>> _services = [];

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
        .channel('public:services_cashier')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'services',
          callback: (_) {
            _fetchServicesOnly();
          },
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
        _services = List<Map<String, dynamic>>.from(servicesRes);
        if (_services.isNotEmpty && _selectedServiceId == null) {
          _selectedServiceId = _services.first['id'] as int?;
        }
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

      _services = List<Map<String, dynamic>>.from(servicesRes);

      if (_services.isNotEmpty && _selectedServiceId == null) {
        _selectedServiceId = _services.first['id'] as int?;
      }

      final bookingsRes = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('assigned_bay', _selectedBay)
          .neq('status', 'completed')
          .neq('status', 'released');

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

  Future<void> _updateQueueCount(int bay) async {
    setState(() => _selectedBay = bay);
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('assigned_bay', bay)
          .neq('status', 'completed')
          .neq('status', 'released');

      if (!mounted) return;
      setState(() {
        _queueAheadCount = res.length;
      });
    } catch (_) {}
  }

  Map<String, dynamic>? get _currentSelectedService {
    if (_services.isEmpty) return null;
    try {
      return _services.firstWhere((s) => s['id'] == _selectedServiceId);
    } catch (_) {
      return _services.first;
    }
  }

  double get _calculatedAmount {
    final s = _currentSelectedService;
    if (s == null) return 500.0;
    return _selectedLocation == 'stationary'
        ? (s['stationary_price'] ?? 500.0).toDouble()
        : (s['mobile_price'] ?? 700.0).toDouble();
  }

  double get _calculatedCommission {
    final s = _currentSelectedService;
    if (s == null) return 100.0;
    return (s['commission_amount'] ?? 100.0).toDouble();
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
      final serviceItem = _currentSelectedService;
      final int finalServiceId = _selectedServiceId ??
          (serviceItem != null ? serviceItem['id'] as int : 1);
      final String vehicleCategory = serviceItem != null
          ? (serviceItem['vehicle_type'] ?? 'TYPE_A').toString()
          : 'TYPE_A';

      final vehicleRes = await Supabase.instance.client
          .from('vehicles')
          .insert({
            'license_plate': _plateController.text.trim().toUpperCase(),
            'make_model': 'Customer Vehicle',
            'category': vehicleCategory,
            'customer_phone': _phoneController.text.trim(),
          })
          .select()
          .single();

      final Map<String, dynamic> bookingPayload = {
        'vehicle_id': vehicleRes['id'],
        'service_id': finalServiceId,
        'source': _selectedSource,
        'location_type': _selectedLocation,
        'total_amount': _calculatedAmount,
        'commission_earned': _calculatedCommission,
        'owner_name': _nameController.text.trim().isEmpty
            ? 'Customer'
            : _nameController.text.trim(),
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
          ? 'Phone booking registered! Tell customer arrival in ~$estWaitMins mins.'
          : 'Customer registered and added to queue successfully!';

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
    final int estimatedWaitMinutes = _queueAheadCount * 45;

    return AlertDialog(
      title: const Text(
        'Cashier Terminal - Customer Intake',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Gate Walk-In',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: ChoiceChip(
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_in_talk, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Phone Call',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
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
                  DropdownButtonFormField<int>(
                    value: _selectedServiceId,
                    decoration: const InputDecoration(
                      labelText: 'Service Package & Price Matrix *',
                      border: OutlineInputBorder(),
                    ),
                    items: _services.map((s) {
                      final String typeLabel = (s['vehicle_type'] ?? 'TYPE_A')
                          .toString()
                          .replaceAll('TYPE_', 'Type ');
                      final double sPrice =
                          (s['stationary_price'] ?? 500).toDouble();
                      final double mPrice =
                          (s['mobile_price'] ?? 700).toDouble();
                      final double price =
                          _selectedLocation == 'stationary' ? sPrice : mPrice;

                      return DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text(
                          '${s['service_name']} ($typeLabel) - $price ETB',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedServiceId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
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
                      onChanged: (val) => _updateQueueCount(val ?? 1),
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
                  const SizedBox(height: 12),
                  if (_selectedLocation == 'stationary')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: AppColors.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bay $_selectedBay Status: $_queueAheadCount vehicle(s) ahead.\nEstimated start in ~$estimatedWaitMinutes mins.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _submitRegistration,
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(_selectedSource == 'phone'
                  ? 'Confirm Phone Booking'
                  : 'Register & Queue'),
        ),
      ],
    );
  }
}
