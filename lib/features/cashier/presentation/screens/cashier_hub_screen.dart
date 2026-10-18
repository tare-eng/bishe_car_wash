import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'cashier_registration_screen.dart';
import 'customer_history_screen.dart';
import 'package:bishe_car_wash/features/cashier/presentation/widgets/payment_verification_dialog.dart';

class CashierHubScreen extends StatefulWidget {
  const CashierHubScreen({super.key});

  @override
  State<CashierHubScreen> createState() => _CashierHubScreenState();
}

class _CashierHubScreenState extends State<CashierHubScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _setupRealtimeSubscription();
  }

  Future<void> _fetchBookings() async {
    try {
      // Exclude completed and released so they move to Customer History
      final response = await _supabase
          .from('bookings')
          .select('*, vehicles(*), services(*), employees(full_name)')
          .neq('status', 'completed')
          .neq('status', 'released')
          .order('id', ascending: false);

      if (!mounted) return;
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('public:bookings_cashier_hub')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _fetchBookings(),
        )
        .subscribe();
  }

  Future<void> _updateStatus(int bookingId, String newStatus) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': newStatus}).eq('id', bookingId);
      _fetchBookings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _openMapWithCoordinates(String addressText) async {
    try {
      if (addressText.contains('Lat:') && addressText.contains('Lng:')) {
        final regExp = RegExp(r'Lat:\s*([-\d.]+),\s*Lng:\s*([-\d.]+)');
        final match = regExp.firstMatch(addressText);

        if (match != null) {
          final lat = match.group(1);
          final lng = match.group(2);

          final url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            return;
          }
        }
      }

      final encodedAddress = Uri.encodeComponent(addressText);
      final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch map: $e');
    }
  }

  void _openRegistrationScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CashierRegistrationScreen(),
      ),
    );
    if (result == true) {
      _fetchBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        title: Text('Cashier Hub (${_bookings.length} In Queue)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Customer History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
            onPressed: _fetchBookings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Exit Hub',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No active vehicles in queue',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final vehicle = booking['vehicles'] ?? {};
                    final service = booking['services'] ?? {};
                    final licensePlate = vehicle['license_plate'] ?? 'UNKNOWN';
                    final paymentStatus =
                        booking['payment_status'] ?? 'pending';
                    final source = booking['source'] ?? 'walk_in';
                    final locationType =
                        booking['location_type'] ?? 'stationary';
                    final deliveryAddress = booking['delivery_address'];

                    final String serviceName =
                        service['service_name'] ?? 'Car Wash';
                    final String vehicleType =
                        (service['vehicle_type'] ?? 'TYPE_A')
                            .toString()
                            .replaceAll('TYPE_', 'Type ');

                    String currentStatus =
                        (booking['status'] ?? 'order_placed').toString();
                    const validStatuses = [
                      'order_placed',
                      'started_washing',
                      'finished',
                      'released',
                    ];
                    if (!validStatuses.contains(currentStatus)) {
                      currentStatus = 'order_placed';
                    }

                    final totalAmount = booking['total_amount'] ?? 0;
                    final commission = booking['commission_earned'] ?? 0;
                    final employee =
                        booking['employees']?['full_name'] ?? 'Unassigned';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${booking['id']} - $licensePlate',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        source.toUpperCase(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: source == 'app'
                                          ? Colors.purple[100]
                                          : Colors.blue[100],
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: paymentStatus == 'verified' ||
                                                paymentStatus == 'paid'
                                            ? Colors.green[100]
                                            : Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        paymentStatus.toUpperCase(),
                                        style: TextStyle(
                                          color: paymentStatus == 'verified' ||
                                                  paymentStatus == 'paid'
                                              ? Colors.green[800]
                                              : Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text(
                              'Service Package: $serviceName ($vehicleType)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text('Service Mode: ${locationType.toUpperCase()}'),
                            if (locationType == 'mobile' &&
                                deliveryAddress != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Location: $deliveryAddress',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primaryBlue),
                                    icon: const Icon(Icons.map, size: 16),
                                    label: const Text('Open Map'),
                                    onPressed: () => _openMapWithCoordinates(
                                        deliveryAddress),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text('Assigned Washer: $employee'),
                            Text(
                              'Amount Due: ETB $totalAmount (Comm: ETB $commission)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DropdownButton<String>(
                                  value: currentStatus,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'order_placed',
                                      child: Text('Booked'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'started_washing',
                                      child: Text('Washing'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'finished',
                                      child: Text('Finished'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'released',
                                      child: Text('Released'),
                                    ),
                                  ],
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      _updateStatus(booking['id'], newStatus);
                                    }
                                  },
                                ),
                                if (paymentStatus != 'verified' &&
                                    paymentStatus != 'paid')
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.successGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Verify Payment'),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            PaymentVerificationDialog(
                                          booking: booking,
                                          onSuccess: _fetchBookings,
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const Text(
                                    'Paid & Verified',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text(
              'Register Walk-In / Phone Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _openRegistrationScreen,
          ),
        ),
      ),
    );
  }
}
