import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/main.dart';
import 'package:bishe_car_wash/l10n/app_localizations.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class AdminServicePricingView extends ConsumerStatefulWidget {
  const AdminServicePricingView({super.key});

  @override
  ConsumerState<AdminServicePricingView> createState() =>
      _AdminServicePricingViewState();
}

class _AdminServicePricingViewState
    extends ConsumerState<AdminServicePricingView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client
          .from('services')
          .select()
          .order('id', ascending: true);

      setState(() {
        _services = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading services: $e')),
        );
      }
    }
  }

  Future<void> _showEditPriceDialog(Map<String, dynamic> service) async {
    final currentPrice = service['price']?.toString() ?? '0';
    final controller = TextEditingController(text: currentPrice);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Price: ${service['name'] ?? service['title'] ?? 'Service'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter new price in ETB:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'ETB',
              ),
            ),
          ],
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
            onPressed: () async {
              final newPrice = double.tryParse(controller.text.trim());
              if (newPrice == null || newPrice < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid price amount.')),
                );
                return;
              }

              Navigator.pop(context);
              await _updateServicePrice(service['id'], newPrice);
            },
            child: const Text('Update Price'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateServicePrice(int serviceId, double newPrice) async {
    try {
      setState(() => _isLoading = true);

      await Supabase.instance.client
          .from('services')
          .update({'price': newPrice}).eq('id', serviceId);

      await _fetchServices();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service price updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update price: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pricingMatrix),
        actions: [
          // Language switcher button for Admin
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.white),
            tooltip: 'Change Language',
            onSelected: (Locale newLocale) {
              ref.read(localeProvider.notifier).state = newLocale;
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('am'), child: Text('አማርኛ')),
              PopupMenuItem(value: Locale('om'), child: Text('Afaan Oromoo')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchServices,
              child: _services.isEmpty
                  ? const Center(child: Text('No service packages found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              service['name'] ??
                                  service['title'] ??
                                  'Unnamed Service',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                service['description'] ??
                                    'Standard Wash Package',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${service['price']} ETB',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.primaryBlue),
                                  onPressed: () =>
                                      _showEditPriceDialog(service),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
