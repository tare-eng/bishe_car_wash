import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class AdminLiveQueueView extends StatefulWidget {
  const AdminLiveQueueView({super.key});

  @override
  State<AdminLiveQueueView> createState() => _AdminLiveQueueViewState();
}

class _AdminLiveQueueViewState extends State<AdminLiveQueueView> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  RealtimeChannel? _bookingsChannel;

  @override
  void initState() {
    super.initState();
    _fetchLiveBookings();
    _setupRealtimeStream();
  }

  void _setupRealtimeStream() {
    _bookingsChannel = Supabase.instance.client
        .channel('public:admin_live_queue')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => _fetchLiveBookings(),
        )
        .subscribe();
  }

  Future<void> _fetchLiveBookings() async {
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(*), employees:employee_id(full_name)')
          .inFilter('status', [
        'order_placed',
        'confirmed',
        'in_progress',
        'washing',
        'ready'
      ]).order('id', ascending: false);

      if (!mounted) return;
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching admin live queue: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bookingsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchLiveBookings,
            child: _bookings.isEmpty
                ? const Center(
                    child: Text(
                      'No active vehicles in the queue.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      final vehicle = booking['vehicles'] ?? {};
                      final plate = vehicle['license_plate'] ?? 'UNKNOWN';
                      final source = booking['source'] ?? 'walk_in';
                      final location = booking['location_type'] ?? 'stationary';
                      final status = booking['status'] ?? 'order_placed';
                      final amount = booking['total_amount'] ?? 0;
                      final washer =
                          booking['employees']?['full_name'] ?? 'Unassigned';
                      final ownerName = booking['owner_name'] ?? 'Customer';

                      Color sourceColor;
                      if (source == 'app') {
                        sourceColor = Colors.purple;
                      } else if (source == 'phone') {
                        sourceColor = Colors.orange;
                      } else {
                        sourceColor = Colors.blue;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Plate: $plate',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      source.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: sourceColor,
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text('Customer: $ownerName'),
                              Text('Service Mode: ${location.toUpperCase()}'),
                              Text('Assigned Washer: $washer'),
                              Text(
                                  'Status: ${status.toUpperCase().replaceAll('_', ' ')}'),
                              Text('Amount: $amount ETB',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
  }
}
