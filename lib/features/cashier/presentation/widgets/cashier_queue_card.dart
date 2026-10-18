import 'package:flutter/material.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'package:bishe_car_wash/features/cashier/presentation/widgets/payment_verification_dialog.dart';

class CashierQueueCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(int id, String status) onUpdateStatus;
  final VoidCallback RefreshQueue;

  const CashierQueueCard({
    super.key,
    required this.booking,
    required this.onUpdateStatus,
    required this.RefreshQueue,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = booking['vehicles'] ?? {};
    final employee = booking['employees'] ?? {};
    final service = booking['services'] ?? {};
    final bool isPaid = booking['payment_status'] == 'paid';

    final String displayVehicleType = (service['vehicle_type'] ?? 'TYPE_A')
        .toString()
        .replaceAll('TYPE_', 'Type ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaid ? AppColors.successGreen : Colors.orange.shade300,
          width: 1.5,
        ),
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
                  vehicle['license_plate'] ?? 'No Plate',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.successGreen.withOpacity(0.15)
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid
                        ? 'PAID (${(booking['payment_method'] ?? 'cash').toString().toUpperCase()})'
                        : 'PENDING PAYMENT',
                    style: TextStyle(
                      color: isPaid
                          ? AppColors.successGreen
                          : Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text('Car Owner: ${booking['owner_name'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Phone: ${vehicle['customer_phone'] ?? 'N/A'}'),
            Text(
                'Service: ${service['service_name'] ?? 'Full Detail'} ($displayVehicleType)'),
            Text('Washer Assigned: ${employee['full_name'] ?? 'Unassigned'}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee: ${booking['total_amount']} ETB',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Row(
                  children: [
                    if (!isPaid)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.verified, size: 18),
                        label: const Text('Verify Payment'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => PaymentVerificationDialog(
                              booking: booking,
                              onSuccess: RefreshQueue,
                            ),
                          );
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) => onUpdateStatus(booking['id'], val),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'order_placed', child: Text('Order Placed')),
                        PopupMenuItem(
                            value: 'arrived_at_bay',
                            child: Text('Arrived at Bay')),
                        PopupMenuItem(
                            value: 'ready_for_pickup',
                            child: Text('Ready for Pickup')),
                        PopupMenuItem(
                            value: 'completed', child: Text('Completed')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
