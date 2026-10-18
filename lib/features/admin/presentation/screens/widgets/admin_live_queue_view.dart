import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bishe_car_wash/core/constants/app_colors.dart';
import 'package:bishe_car_wash/main.dart';
import 'package:bishe_car_wash/features/queue/presentation/widgets/shared_queue_tracker_widget.dart';

class AdminLiveQueueView extends ConsumerStatefulWidget {
  const AdminLiveQueueView({super.key});

  @override
  ConsumerState<AdminLiveQueueView> createState() => _AdminLiveQueueViewState();
}

class _AdminLiveQueueViewState extends ConsumerState<AdminLiveQueueView> {
  Future<void> _refreshQueueStub() async {
    // The SharedQueueTrackerWidget listens to real-time streams automatically.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Live Queue'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          // Language Switcher (EN & AM only for Admin Portal)
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language_rounded, color: Colors.white),
            tooltip: 'Language / ቋንቋ',
            onSelected: (Locale newLocale) {
              ref.read(localeProvider.notifier).state = newLocale;
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: Locale('en'), child: Text('English')),
              PopupMenuItem(value: Locale('am'), child: Text('አማርኛ (Amharic)')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshQueueStub,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: SharedQueueTrackerWidget(isStaff: true),
        ),
      ),
    );
  }
}
