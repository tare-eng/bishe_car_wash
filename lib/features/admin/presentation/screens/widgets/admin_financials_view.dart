import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class AdminFinancialsView extends StatefulWidget {
  const AdminFinancialsView({super.key});

  @override
  State<AdminFinancialsView> createState() => _AdminFinancialsViewState();
}

class _AdminFinancialsViewState extends State<AdminFinancialsView> {
  double _totalRevenue = 0.0;
  double _totalCommissions = 0.0;
  int _totalOrders = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFinancials();
  }

  Future<void> _fetchFinancials() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client.from('bookings').select();
      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(res);

      double rev = 0.0;
      double comm = 0.0;

      for (var item in data) {
        if (item['payment_status'] == 'paid' ||
            item['payment_status'] == 'verified' ||
            item['status'] == 'completed') {
          rev += (item['total_amount'] ?? 0.0) as num;
          comm += (item['commission_earned'] ?? 0.0) as num;
        }
      }

      setState(() {
        _totalRevenue = rev;
        _totalCommissions = comm;
        _totalOrders = data.length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchFinancials,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'BISHE Financial Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Total Gross Revenue',
                  value: '$_totalRevenue ETB',
                  icon: Icons.monetization_on,
                  color: AppColors.successGreen,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Washer Commissions Paid',
                  value: '$_totalCommissions ETB',
                  icon: Icons.payments_outlined,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Net Business Margin',
                  value: '${_totalRevenue - _totalCommissions} ETB',
                  icon: Icons.account_balance_wallet,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 12),
                _StatCard(
                  title: 'Total Service Bookings',
                  value: '$_totalOrders Orders',
                  icon: Icons.directions_car,
                  color: Colors.purple.shade700,
                ),
              ],
            ),
          );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
