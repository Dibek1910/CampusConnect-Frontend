import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/providers/appointment_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/widgets/status_badge.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/widgets/custom_tab_bar.dart';
import 'package:campus_connect/config/theme.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      await appointmentProvider.fetchStudentAppointments();
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to cancel this appointment?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, reasonController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (reason != null) {
      final appointmentProvider = Provider.of<AppointmentProvider>(
        context,
        listen: false,
      );
      final success = await appointmentProvider.cancelAppointment(
        appointmentId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (success) {
        _showSnackBar('Appointment cancelled successfully');
      } else {
        _showSnackBar(
          appointmentProvider.error ?? 'Failed to cancel appointment',
        );
      }
    }
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
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final pendingAppointments = appointmentProvider.getFilteredAppointments(
      'pending',
    );
    final acceptedAppointments = appointmentProvider.getFilteredAppointments(
      'accepted',
    );
    final rejectedAppointments = appointmentProvider.getFilteredAppointments(
      'rejected',
    );
    final completedAppointments = appointmentProvider.getFilteredAppointments(
      'completed',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
            Tab(text: 'Completed'),
          ],
          indicatorWeight: 3.0,
          indicatorColor: Colors.white,
        ),
        elevation: 4,
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading appointments...')
              : appointmentProvider.error != null
              ? ErrorDisplay(
                message: 'Error: ${appointmentProvider.error}',
                onRetry: _loadAppointments,
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentList(pendingAppointments, 'pending'),
                  _buildAppointmentList(acceptedAppointments, 'accepted'),
                  _buildAppointmentList(rejectedAppointments, 'rejected'),
                  _buildAppointmentList(completedAppointments, 'completed'),
                ],
              ),
    );
  }

  Widget _buildAppointmentList(
    List<AppointmentModel> appointments,
    String status,
  ) {
    return appointments.isEmpty
        ? EmptyState(
          message: 'No $status appointments',
          subMessage: 'Pull down to refresh',
          icon: _getStatusIcon(status),
          onAction: _loadAppointments,
          actionLabel: 'Refresh',
        )
        : RefreshIndicator(
          onRefresh: _loadAppointments,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
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
                                appointment.facultyName.isNotEmpty
                                    ? appointment.facultyName[0].toUpperCase()
                                    : 'F',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.facultyName,
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
                            StatusBadge(
                              status: appointment.status,
                              animate: true,
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          'Time: ${appointment.startTime} - ${appointment.endTime}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        if (appointment.purposeCategory != null) ...[
                          Text(
                            'Category: ${appointment.purposeCategory}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'Purpose: ${appointment.purpose}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (appointment.isDirectRequest) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Duration: ${appointment.duration} minutes',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                        if (appointment.status == 'rejected' &&
                            appointment.cancelReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${appointment.cancelReason}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                        if (appointment.status == 'accepted') ...[
                          const SizedBox(height: 16),
                          ButtonWidget(
                            text: 'Cancel Appointment',
                            onPressed: () => _cancelAppointment(appointment.id),
                            backgroundColor: AppTheme.errorColor,
                            isOutlined: true,
                            width: double.infinity,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.event_available;
      case 'rejected':
        return Icons.event_busy;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.event_note;
    }
  }
}
