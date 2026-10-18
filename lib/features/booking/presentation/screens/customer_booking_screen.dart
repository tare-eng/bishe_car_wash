import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class CustomerBookingScreen extends StatefulWidget {
  const CustomerBookingScreen({super.key});

  @override
  State<CustomerBookingScreen> createState() => _CustomerBookingScreenState();
}

class _CustomerBookingScreenState extends State<CustomerBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<Map<String, dynamic>> _services = [];
  int? _selectedServiceId;
  String _locationType = 'stationary';

  bool _isLoading = false;
  bool _isFetchingServices = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final res = await _supabase.from('services').select('*');
      if (!mounted) return;
      setState(() {
        _services = List<Map<String, dynamic>>.from(res);
        if (_services.isNotEmpty) {
          _selectedServiceId = _services.first['id'] as int?;
        }
        _isFetchingServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingServices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load services: $e')),
      );
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car wash service.')),
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

      final currentUser = _supabase.auth.currentUser;

      final bookingResponse = await _supabase
          .from('bookings')
          .insert({
            'customer_id': currentUser?.id,
            'vehicle_id': vehicleId,
            'service_id': _selectedServiceId,
            'owner_name': ownerName,
            'source': 'app',
            'location_type': _locationType,
            'delivery_address': _locationType == 'mobile'
                ? _addressController.text.trim()
                : null,
            'status': 'order_placed',
            'payment_status': 'pending',
            'total_amount': totalAmount,
          })
          .select('id')
          .single();

      final int createdBookingId = bookingResponse['id'] as int;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('latest_booking_id', createdBookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text(
              'Booking #$createdBookingId placed successfully! Track your queue position below.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place booking: $e')),
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
        title: const Text('Book Car Wash'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isFetchingServices
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Vehicle Details',
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
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licensePlateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'License Plate (e.g. ET-2-99881)',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter license plate'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter contact number'
                          : null,
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Service Options',
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
                        labelText: 'Select Wash Package',
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
                    DropdownButtonFormField<String>(
                      value: _locationType,
                      decoration: const InputDecoration(
                        labelText: 'Service Mode',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'stationary',
                          child: Text('Drive-In (At Wash Station)'),
                        ),
                        DropdownMenuItem(
                          value: 'mobile',
                          child: Text('Mobile Service (At My Location)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _locationType = val ?? 'stationary'),
                    ),
                    if (_locationType == 'mobile') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery / Location Address',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => _locationType == 'mobile' &&
                                (val == null || val.trim().isEmpty)
                            ? 'Please enter your location'
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
                            : const Icon(Icons.check_circle_outline),
                        label: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit & Enter Live Queue',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        onPressed: _isLoading ? null : _submitBooking,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
