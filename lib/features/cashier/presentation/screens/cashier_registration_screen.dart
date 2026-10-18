import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class CashierRegistrationScreen extends StatefulWidget {
  const CashierRegistrationScreen({super.key});

  @override
  State<CashierRegistrationScreen> createState() =>
      _CashierRegistrationScreenState();
}

class _CashierRegistrationScreenState extends State<CashierRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _employees = [];

  int? _selectedServiceId;
  int? _selectedEmployeeId;
  String _selectedSource = 'walk_in';
  String _selectedLocationType = 'stationary';
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final servicesRes = await _supabase.from('services').select('*');
      final employeesRes = await _supabase.from('employees').select('*');

      if (!mounted) return;
      setState(() {
        _services = List<Map<String, dynamic>>.from(servicesRes);
        _employees = List<Map<String, dynamic>>.from(employeesRes);
        if (_services.isNotEmpty) {
          _selectedServiceId = _services.first['id'] as int?;
        }
        _isInitialFetching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isInitialFetching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load services or staff: $e')),
      );
    }
  }

  Future<void> _registerCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service package.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final plate = _licensePlateController.text.trim().toUpperCase();
      final ownerName = _ownerNameController.text.trim();
      final phone = _phoneController.text.trim();

      final existingVehicle = await _supabase
          .from('vehicles')
          .select('id')
          .eq('license_plate', plate)
          .maybeSingle();

      int vehicleId;
      if (existingVehicle != null) {
        vehicleId = existingVehicle['id'] as int;
      } else {
        final newVehicle = await _supabase
            .from('vehicles')
            .insert({
              'license_plate': plate,
              'owner_name': ownerName,
              'phone_number': phone,
            })
            .select('id')
            .single();
        vehicleId = newVehicle['id'] as int;
      }

      final serviceData =
          _services.firstWhere((s) => s['id'] == _selectedServiceId);
      final double totalAmount = (serviceData['price'] ?? 0.0).toDouble();

      final double commission = totalAmount * 0.10;

      final currentUser = _supabase.auth.currentUser;

      await _supabase.from('bookings').insert({
        'vehicle_id': vehicleId,
        'service_id': _selectedServiceId,
        'owner_name': ownerName,
        'source': _selectedSource,
        'location_type': _selectedLocationType,
        'delivery_address': _selectedLocationType == 'mobile'
            ? _addressController.text.trim()
            : null,
        'status': 'order_placed',
        'payment_status': 'pending',
        'total_amount': totalAmount,
        'commission_earned': commission,
        'employee_id': _selectedEmployeeId,
        'cashier_id': currentUser?.id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content:
              Text('Customer $ownerName ($plate) registered successfully!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _licensePlateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Walk-In / Phone Customer'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isInitialFetching
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer & Vehicle Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter customer name'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate (e.g. AA-3-12345)',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter license plate'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Service & Booking Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedServiceId,
                      decoration: const InputDecoration(
                        labelText: 'Select Service Package',
                        prefixIcon: Icon(Icons.local_car_wash),
                        border: OutlineInputBorder(),
                      ),
                      items: _services.map((service) {
                        final price = service['price'] ?? 0;
                        final name = service['service_name'] ?? 'Wash';
                        return DropdownMenuItem<int>(
                          value: service['id'] as int,
                          child: Text('$name - ETB $price'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedServiceId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedEmployeeId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Washer (Optional)',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Unassigned / Next Available'),
                        ),
                        ..._employees.map((e) {
                          return DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(e['full_name'] ?? 'Washer'),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedEmployeeId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSource,
                            decoration: const InputDecoration(
                              labelText: 'Booking Channel',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'walk_in', child: Text('Walk-In')),
                              DropdownMenuItem(
                                  value: 'phone', child: Text('Phone Call')),
                            ],
                            onChanged: (val) => setState(
                                () => _selectedSource = val ?? 'walk_in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocationType,
                            decoration: const InputDecoration(
                              labelText: 'Service Mode',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'stationary',
                                  child: Text('Stationary')),
                              DropdownMenuItem(
                                  value: 'mobile',
                                  child: Text('Mobile Service')),
                            ],
                            onChanged: (val) => setState(() =>
                                _selectedLocationType = val ?? 'stationary'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLocationType == 'mobile') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery / Mobile Location Address',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            _selectedLocationType == 'mobile' &&
                                    (value == null || value.trim().isEmpty)
                                ? 'Please provide delivery address'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_circle),
                        label: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Confirm & Register Customer',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        onPressed: _isLoading ? null : _registerCustomer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
