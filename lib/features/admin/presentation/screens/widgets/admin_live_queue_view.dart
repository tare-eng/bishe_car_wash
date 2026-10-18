import 'package:flutter/material.dart';
import 'package:bishe_car_wash/features/queue/presentation/widgets/shared_queue_tracker_widget.dart';

class AdminLiveQueueView extends StatelessWidget {
  const AdminLiveQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshQueueStub,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.0),
          child: SharedQueueTrackerWidget(isStaff: true),
        ),
      ),
    );
  }

  static Future<void> _refreshQueueStub() async {
    // The SharedQueueTrackerWidget listens to real-time streams automatically.
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
