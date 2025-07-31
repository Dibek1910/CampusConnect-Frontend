import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/widgets/status_badge.dart';
import 'package:campus_connect/config/theme.dart';

class AppointmentRequestsScreen extends StatefulWidget {
  const AppointmentRequestsScreen({super.key});

  @override
  State<AppointmentRequestsScreen> createState() =>
      _AppointmentRequestsScreenState();
}

class _AppointmentRequestsScreenState extends State<AppointmentRequestsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );
      await facultyProvider.fetchFacultyAppointments();
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAppointmentStatus(
    String appointmentId,
    String status, {
    String? reason,
  }) async {
    final facultyProvider = Provider.of<FacultyProvider>(
      context,
      listen: false,
    );
    final success = await facultyProvider.updateAppointmentStatus(
      appointmentId,
      status,
      reason: reason,
    );

    if (success) {
      _showSnackBar('Appointment $status successfully');
    } else {
      _showSnackBar(
        facultyProvider.error ?? 'Failed to update appointment status',
      );
    }
  }

  void _showRejectDialog(String appointmentId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateAppointmentStatus(
                    appointmentId,
                    'rejected',
                    reason: reasonController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facultyProvider = Provider.of<FacultyProvider>(context);

    final pendingAppointments =
        facultyProvider.appointments
            .where((appointment) => appointment.status == 'pending')
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Requests'), elevation: 4),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading requests...')
              : facultyProvider.error != null
              ? ErrorDisplay(
                message: 'Error: ${facultyProvider.error}',
                onRetry: _loadAppointments,
              )
              : pendingAppointments.isEmpty
              ? EmptyState(
                message: 'No pending appointment requests',
                subMessage: 'Pull down to refresh',
                icon: Icons.calendar_today_outlined,
                onAction: _loadAppointments,
                actionLabel: 'Refresh',
              )
              : RefreshIndicator(
                onRefresh: _loadAppointments,
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = pendingAppointments[index];
                    return AnimatedListItem(
                      delay: Duration(milliseconds: 50 * index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.2),
                                    child: Text(
                                      appointment.studentName.isNotEmpty
                                          ? appointment.studentName[0]
                                              .toUpperCase()
                                          : 'S',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment.studentName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Date: ${appointment.date.toString().split(' ')[0]}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(status: 'pending'),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                'Time: ${appointment.startTime} - ${appointment.endTime}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Purpose: ${appointment.purpose}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ButtonWidget(
                                      text: 'Accept',
                                      onPressed:
                                          () => _updateAppointmentStatus(
                                            appointment.id,
                                            'accepted',
                                          ),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ButtonWidget(
                                      text: 'Reject',
                                      onPressed:
                                          () =>
                                              _showRejectDialog(appointment.id),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
