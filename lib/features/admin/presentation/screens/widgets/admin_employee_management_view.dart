import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';

class AdminEmployeeManagementView extends StatefulWidget {
  const AdminEmployeeManagementView({super.key});

  @override
  State<AdminEmployeeManagementView> createState() =>
      _AdminEmployeeManagementViewState();
}

class _AdminEmployeeManagementViewState
    extends State<AdminEmployeeManagementView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedRole = 'washer';

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('employees')
          .select()
          .order('id', ascending: false);

      setState(() {
        _employees = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEmployee() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter employee full name')),
      );
      return;
    }

    if ((_selectedRole == 'cashier' || _selectedRole == 'admin') &&
        _pinController.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a 4-digit PIN for portal login')),
      );
      return;
    }

    try {
      final Map<String, dynamic> data = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
      };

      if (_pinController.text.trim().isNotEmpty) {
        data['pin'] = _pinController.text.trim();
      }

      await Supabase.instance.client.from('employees').insert(data);

      _nameController.clear();
      _phoneController.clear();
      _pinController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.successGreen,
          content: Text('Employee registered successfully!'),
        ),
      );

      _fetchEmployees();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding employee: $e')),
      );
    }
  }

  Future<void> _deleteEmployee(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Staff: $name?'),
        content: const Text(
            'Are you sure you want to remove this staff member from the system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('employees').delete().eq('id', id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Staff member deleted successfully'),
          ),
        );
        _fetchEmployees();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting staff: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record New Staff Member',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name (e.g. Abebe Bikila)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Staff Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'washer', child: Text('Washer Staff')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedRole = val ?? 'washer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedRole == 'cashier' || _selectedRole == 'admin') ...[
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '4-Digit Login PIN',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Save Employee to System'),
              onPressed: _addEmployee,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Active Staff Roster',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _employees.isEmpty
                  ? const Text('No staff members registered yet.')
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        final emp = _employees[index];
                        final hasPin = emp['pin'] != null &&
                            emp['pin'].toString().isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primaryBlue.withOpacity(0.2),
                              child: Text(
                                (emp['full_name'] ?? 'E')[0].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              emp['full_name'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Role: ${emp['role']} | Phone: ${emp['phone'] ?? 'N/A'}${hasPin ? ' | PIN Assigned' : ''}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEmployee(
                                emp['id'] as int,
                                emp['full_name'] ?? 'Staff',
                              ),
                              tooltip: 'Delete Staff',
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
