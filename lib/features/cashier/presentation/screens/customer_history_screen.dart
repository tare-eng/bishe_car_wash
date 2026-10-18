import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await Supabase.instance.client
          .from('bookings')
          .select('*, vehicles(*), services(*), employees(full_name)')
          .or('status.eq.finished,status.eq.released')
          .order('id', ascending: false);

      if (!mounted) return;
      setState(() {
        _history = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finished & Released History'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Text(
                    'No finished or released customer records yet.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final vehicle = item['vehicles'] ?? {};
                    final service = item['services'] ?? {};
                    final employee =
                        item['employees']?['full_name'] ?? 'Unassigned';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          '${vehicle['license_plate'] ?? 'N/A'} - ${item['owner_name'] ?? 'Customer'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Service: ${service['service_name'] ?? 'Wash'} | Washer: $employee\nAmount Paid: ETB ${item['total_amount']}',
                        ),
                        trailing: Chip(
                          label: Text(
                            (item['status'] ?? 'FINISHED')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: Colors.green[700],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
