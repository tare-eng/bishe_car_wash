import 'package:flutter/material.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'widgets/admin_financials_view.dart';
import 'widgets/admin_live_queue_view.dart';
import 'widgets/admin_service_pricing_view.dart';
import 'widgets/admin_employee_management_view.dart';
import 'package:bishe_car_wash/features/cashier/presentation/screens/customer_history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0;

  final List<Widget> _adminTabs = const [
    AdminLiveQueueView(),
    CustomerHistoryScreen(),
    AdminFinancialsView(),
    AdminServicePricingView(),
    AdminEmployeeManagementView(),
  ];

  final List<String> _tabTitles = const [
    'Live Operations Queue',
    'Released Customers & History',
    'Financials & Revenue Overview',
    'Service Pricing Matrix',
    'Employee Staff Management',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedTab]),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Exit Portal',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: _adminTabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Live Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Financials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.price_change),
            label: 'Pricing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Employees',
          ),
        ],
      ),
    );
  }
}
