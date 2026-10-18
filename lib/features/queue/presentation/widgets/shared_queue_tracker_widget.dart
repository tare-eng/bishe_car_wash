import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class SharedQueueTrackerWidget extends StatefulWidget {
  final bool isStaff; // true for Admin/Cashier, false for Anonymous Customers
  final int? bayFilter; // Optional filter for specific bay (1 or 2)

  const SharedQueueTrackerWidget({
    super.key,
    required this.isStaff,
    this.bayFilter,
  });

  @override
  State<SharedQueueTrackerWidget> createState() =>
      _SharedQueueTrackerWidgetState();
}

class _SharedQueueTrackerWidgetState extends State<SharedQueueTrackerWidget> {
  bool _isLoading = true;
  int _vehiclesAhead = 0;
  int _estimatedMinutes = 0;
  String _targetArrival = '';
  List<Map<String, dynamic>> _staffQueueList = [];
  RealtimeChannel? _queueChannel;

  @override
  void initState() {
    super.initState();
    _fetchQueueData();
    _setupRealtime();
  }

  void _setupRealtime() {
    _queueChannel = Supabase.instance.client
        .channel('public:shared_queue_tracker')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _fetchQueueData(),
        )
        .subscribe();
  }

  Future<void> _fetchQueueData() async {
    try {
      final query = Supabase.instance.client
          .from('bookings')
          .select(
              '*, vehicles(*), employees:employee_id(full_name), services(*)')
          .inFilter('status',
              ['order_placed', 'confirmed', 'in_progress', 'washing', 'ready']);

      if (widget.bayFilter != null && widget.isStaff) {
        query.eq('assigned_bay', widget.bayFilter!);
      }

      final res = await query.order('id', ascending: true);
      List<Map<String, dynamic>> bookings =
          List<Map<String, dynamic>>.from(res);

      if (!widget.isStaff) {
        // Customer Privacy View: Check local storage for their active booking ID
        final prefs = await SharedPreferences.getInstance();
        final int? myBookingId = prefs.getInt('latest_booking_id');

        if (myBookingId != null) {
          int myIndex = bookings.indexWhere((b) => b['id'] == myBookingId);
          if (myIndex != -1) {
            // Count vehicles ahead in line relative to this customer
            _vehiclesAhead = myIndex;
            // Factoring in 2 parallel stationary bays: (vehiclesAhead / 2) * 45 mins per wash cycle
            _estimatedMinutes = ((_vehiclesAhead / 2).ceil()) * 45;
            _targetArrival = _calculateArrivalTime(_estimatedMinutes);
          } else {
            // Fallback to total active station count if booking is completed/not found
            _vehiclesAhead = bookings.length;
            _estimatedMinutes = ((_vehiclesAhead / 2).ceil()) * 45;
            _targetArrival = _calculateArrivalTime(_estimatedMinutes);
          }
        } else {
          // No booking stored yet, show total active station queue
          _vehiclesAhead = bookings.length;
          _estimatedMinutes = ((_vehiclesAhead / 2).ceil()) * 45;
          _targetArrival = _calculateArrivalTime(_estimatedMinutes);
        }
      } else {
        _staffQueueList = bookings;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching shared queue tracker: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _calculateArrivalTime(int waitMins) {
    final arrival = DateTime.now().add(Duration(minutes: waitMins));
    final hour = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _queueChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- PRIVACY VIEW FOR ANONYMOUS CUSTOMERS ---
    if (!widget.isStaff) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_filled,
                size: 32, color: AppColors.primaryBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Queue: $_vehiclesAhead vehicle(s) ahead',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estimated Wait: ~$_estimatedMinutes mins (Arrival by $_targetArrival)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // --- FULL DETAIL VIEW FOR STAFF (ADMIN & CASHIER) ---
    else {
      if (_staffQueueList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No active vehicles in the queue.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _staffQueueList.length,
        itemBuilder: (context, index) {
          final booking = _staffQueueList[index];
          final vehicle = booking['vehicles'] ?? {};
          final employee = booking['employees'] ?? {};
          final service = booking['services'] ?? {};

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: Text(
                'Plate: ${vehicle['license_plate'] ?? 'N/A'} (${booking['owner_name'] ?? 'Customer'})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Service: ${service['service_name'] ?? 'Wash'} | Bay: ${booking['assigned_bay'] ?? 'Mobile'} | Washer: ${employee['full_name'] ?? 'Unassigned'}',
              ),
              trailing: Chip(
                label: Text(
                  (booking['status'] ?? 'pending')
                      .toString()
                      .toUpperCase()
                      .replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          );
        },
      );
    }
  }
}
