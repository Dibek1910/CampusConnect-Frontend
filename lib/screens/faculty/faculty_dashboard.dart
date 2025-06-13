import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/models/appointment_model.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/widgets/custom_tab_bar.dart';
import 'package:campus_connect/widgets/status_badge.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/config/theme.dart';

class FacultyDashboardScreen extends StatefulWidget {
  const FacultyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final _scrollController = ScrollController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Changed to 5 tabs

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.logout();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.roleSelectionRoute, (route) => false);
    } else {
      _showSnackBar(authProvider.error ?? 'Logout failed');
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

  Future<void> _completeAppointment(String appointmentId) async {
    final facultyProvider = Provider.of<FacultyProvider>(
      context,
      listen: false,
    );
    final success = await facultyProvider.completeAppointment(appointmentId);

    if (success) {
      _showSnackBar('Appointment marked as completed successfully');
    } else {
      _showSnackBar(facultyProvider.error ?? 'Failed to complete appointment');
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
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );
      final success = await facultyProvider.cancelAppointment(
        appointmentId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (success) {
        _showSnackBar('Appointment cancelled successfully');
      } else {
        _showSnackBar(facultyProvider.error ?? 'Failed to cancel appointment');
      }
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

  void _navigateToManageAvailability() {
    Navigator.of(context).pushNamed(AppRouter.availabilityManagementRoute);
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed(AppRouter.facultyProfileRoute);
  }

  List<AppointmentModel> _filterAppointments(String status) {
    final facultyProvider = Provider.of<FacultyProvider>(context);
    return facultyProvider.appointments
        .where((appointment) => appointment.status == status)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final facultyProfile = authProvider.facultyProfile;

    String departmentName = '';
    if (facultyProfile != null && facultyProfile.department != null) {
      if (facultyProfile.department is Map) {
        departmentName = facultyProfile.department['name'] ?? '';
      } else {
        departmentName = facultyProfile.department.toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Faculty Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            height: 48.0,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Make tabs scrollable
              tabAlignment: TabAlignment.start, // Align tabs to start
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Add padding
              tabs: const [
                Tab(
                  child: Text(
                    'Pending',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Tab(
                  child: Text(
                    'Accepted',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Tab(
                  child: Text(
                    'Rejected',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Tab(
                  child: Text(
                    'Completed',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Tab(
                  child: Text(
                    'Cancelled',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              indicatorWeight: 3.0,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
        ),
        elevation: 4,
      ),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading appointments...')
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (facultyProfile != null)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryColor
                                        .withOpacity(0.2),
                                    child: Text(
                                      facultyProfile.name.isNotEmpty
                                          ? facultyProfile.name[0].toUpperCase()
                                          : 'F',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
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
                                          'Welcome, ${facultyProfile.name}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Department: $departmentName',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _navigateToManageAvailability,
                                icon: const Icon(Icons.schedule),
                                label: const Text('Manage Availability'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child:
                          facultyProvider.isLoading
                              ? const LoadingIndicator()
                              : facultyProvider.error != null
                              ? ErrorDisplay(
                                message: 'Error: ${facultyProvider.error}',
                                onRetry: _loadAppointments,
                              )
                              : TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildAppointmentList('pending'),
                                  _buildAppointmentList('accepted'),
                                  _buildAppointmentList('rejected'),
                                  _buildAppointmentList('completed'),
                                  _buildAppointmentList(
                                    'cancelled',
                                  ), // Added cancelled tab view
                                ],
                              ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final appointments = _filterAppointments(status);

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
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return AnimatedListItem(
                delay: Duration(milliseconds: 50 * index),
                child: _buildAppointmentCard(appointment, status),
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
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.event_note;
    }
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    appointment.studentName.isNotEmpty
                        ? appointment.studentName[0].toUpperCase()
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: appointment.status, animate: true),
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
            if (appointment.status == 'rejected' &&
                appointment.cancelReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rejection Reason: ${appointment.cancelReason}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
            if (appointment.status == 'cancelled' &&
                appointment.cancelReason != null) ...[
              const SizedBox(height: 8),
              Text(
                'Cancellation Reason: ${appointment.cancelReason}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
            if (appointment.status == 'pending') ...[
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
                      onPressed: () => _showRejectDialog(appointment.id),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ],
            if (appointment.status == 'accepted') ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ButtonWidget(
                    text: 'Complete',
                    onPressed: () => _completeAppointment(appointment.id),
                    backgroundColor: AppTheme.accentColor,
                    width: double.infinity,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  ButtonWidget(
                    text: 'Cancel Appointment',
                    onPressed: () => _cancelAppointment(appointment.id),
                    backgroundColor: AppTheme.errorColor,
                    isOutlined: true,
                    width: double.infinity,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
