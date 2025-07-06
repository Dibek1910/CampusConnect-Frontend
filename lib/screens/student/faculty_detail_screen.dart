import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/providers/faculty_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/widgets/animated_list_item.dart';
import 'package:campus_connect/config/theme.dart';

class FacultyDetailScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;

  const FacultyDetailScreen({
    Key? key,
    required this.facultyId,
    required this.facultyName,
  }) : super(key: key);

  @override
  State<FacultyDetailScreen> createState() => _FacultyDetailScreenState();
}

class _FacultyDetailScreenState extends State<FacultyDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFacultyAvailability();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFacultyAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final facultyProvider = Provider.of<FacultyProvider>(
        context,
        listen: false,
      );
      await facultyProvider.fetchFacultyAvailability(widget.facultyId);
    } catch (e) {
      print('Error loading faculty availability: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToBookAppointment(AvailabilityModel availability) {
    Navigator.of(context).pushNamed(
      AppRouter.bookAppointmentRoute,
      arguments: {
        'facultyId': widget.facultyId,
        'facultyName': widget.facultyName,
        'availabilityId': availability.id,
        'day': availability.day,
        'date': availability.date,
        'startTime': availability.startTime,
        'endTime': availability.endTime,
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final facultyProvider = Provider.of<FacultyProvider>(context);
    final availabilities = facultyProvider.availabilities;

    Map<String, List<AvailabilityModel>> availabilitiesByDate = {};

    for (var availability in availabilities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(availability.date);
      if (!availabilitiesByDate.containsKey(dateKey)) {
        availabilitiesByDate[dateKey] = [];
      }
      availabilitiesByDate[dateKey]!.add(availability);
    }

    final sortedDates =
        availabilitiesByDate.keys.toList()..sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(title: Text(widget.facultyName), elevation: 4),
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading availability...')
              : facultyProvider.error != null
              ? ErrorDisplay(
                message: 'Error: ${facultyProvider.error}',
                onRetry: _loadFacultyAvailability,
              )
              : RefreshIndicator(
                onRefresh: _loadFacultyAvailability,
                color: AppTheme.primaryColor,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
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
                                    Hero(
                                      tag: 'faculty-avatar-${widget.facultyId}',
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: AppTheme.primaryColor
                                            .withOpacity(0.2),
                                        child: Text(
                                          widget.facultyName.isNotEmpty
                                              ? widget.facultyName[0]
                                                  .toUpperCase()
                                              : 'F',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.facultyName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Available Time Slots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a time slot to book an appointment',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        availabilities.isEmpty
                            ? EmptyState(
                              message:
                                  'No availability slots found for this faculty',
                              subMessage:
                                  'Pull down to refresh or try again later',
                              icon: Icons.event_busy,
                              onAction: _loadFacultyAvailability,
                              actionLabel: 'Refresh',
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedDates.length,
                              itemBuilder: (context, index) {
                                final dateKey = sortedDates[index];
                                final dateAvailabilities =
                                    availabilitiesByDate[dateKey] ?? [];
                                final date = DateTime.parse(dateKey);

                                return AnimatedListItem(
                                  delay: Duration(milliseconds: 100 * index),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _formatDate(date),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            dateAvailabilities.map((
                                              availability,
                                            ) {
                                              return InkWell(
                                                onTap:
                                                    availability.isAvailable
                                                        ? () =>
                                                            _navigateToBookAppointment(
                                                              availability,
                                                            )
                                                        : null,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color:
                                                          availability
                                                                  .isAvailable
                                                              ? AppTheme
                                                                  .primaryColor
                                                              : Colors.grey,
                                                      width: 1.5,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    color:
                                                        availability.isAvailable
                                                            ? Colors.transparent
                                                            : Colors.grey
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                  ),
                                                  child: Text(
                                                    '${availability.startTime} - ${availability.endTime}',
                                                    style: TextStyle(
                                                      color:
                                                          availability
                                                                  .isAvailable
                                                              ? AppTheme
                                                                  .primaryColor
                                                              : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
