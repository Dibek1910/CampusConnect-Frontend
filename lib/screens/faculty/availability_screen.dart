import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/providers/availability_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/time_input_widget.dart';
import 'package:campus_connect/widgets/time_slot_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/config/theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _startTime = '09:00';
  String _endTime = '18:00';
  bool _isAdding = false;
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
    _animationController.forward();

    _setDefaultDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailabilities();
    });
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    if (now.weekday > 5) {
      _selectedDate = now.add(Duration(days: 8 - now.weekday));
    } else {
      _selectedDate = now;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilities() async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    );
    await availabilityProvider.fetchFacultyAvailabilities();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        return date.weekday >= 1 && date.weekday <= 5;
      },
      helpText: 'Select availability date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addAvailabilitySlot() async {
    final startTimeParts = _startTime.split(':');
    final endTimeParts = _endTime.split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    if (startHour < 9 || startHour >= 18) {
      _showSnackBar('Start time must be between 9:00 AM and 6:00 PM');
      return;
    }

    if (endHour < 9 || endHour > 18) {
      _showSnackBar('End time must be between 9:00 AM and 6:00 PM');
      return;
    }

    if (endHour < startHour ||
        (endHour == startHour && endMinute <= startMinute)) {
      _showSnackBar('End time must be after start time');
      return;
    }

    final now = DateTime.now();
    if (_selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year) {
      final currentHour = now.hour;
      final currentMinute = now.minute;

      if (startHour < currentHour ||
          (startHour == currentHour && startMinute <= currentMinute)) {
        _showSnackBar('Cannot set availability for past time slots');
        return;
      }
    }

    setState(() {
      _isAdding = true;
    });

    final availabilityProvider = Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    );

    final slotData = {
      'date': _selectedDate.toIso8601String(),
      'startTime': _startTime,
      'endTime': _endTime,
    };

    final success = await availabilityProvider.addAvailabilitySlot(slotData);

    setState(() {
      _isAdding = false;
    });

    if (success) {
      _startTime = '09:00';
      _endTime = '18:00';
      _showSnackBar('Availability slot added successfully');
    } else {
      _showSnackBar(
        availabilityProvider.error ?? 'Failed to add availability slot',
      );
    }
  }

  Future<void> _deleteAvailabilitySlot(String slotId) async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    );

    final success = await availabilityProvider.deleteAvailabilitySlot(slotId);

    if (success) {
      _showSnackBar('Availability slot deleted successfully');
    } else {
      _showSnackBar(
        availabilityProvider.error ?? 'Failed to delete availability slot',
      );
    }
  }

  Future<void> _updateAvailabilitySlot(
    String slotId,
    Map<String, dynamic> slotData,
  ) async {
    final availabilityProvider = Provider.of<AvailabilityProvider>(
      context,
      listen: false,
    );

    final success = await availabilityProvider.updateAvailabilitySlot(
      slotId,
      slotData,
    );

    if (success) {
      _showSnackBar('Availability slot updated successfully');
    } else {
      _showSnackBar(
        availabilityProvider.error ?? 'Failed to update availability slot',
      );
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

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final availabilityProvider = Provider.of<AvailabilityProvider>(context);
    final availabilities = availabilityProvider.availabilities;

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
      appBar: AppBar(title: const Text('Manage Availability'), elevation: 4),
      body:
          availabilityProvider.isLoading
              ? const LoadingIndicator(message: 'Loading availability slots...')
              : availabilityProvider.error != null
              ? ErrorDisplay(
                message: 'Error: ${availabilityProvider.error}',
                onRetry: _loadAvailabilities,
              )
              : RefreshIndicator(
                onRefresh: _loadAvailabilities,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add New Availability Slot',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Date:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.white,
                                            ),
                                            child: Text(
                                              _formatDate(_selectedDate),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color:
                                                    AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _selectDate(context),
                                      icon: const Icon(Icons.calendar_today),
                                      label: const Text('Select'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                TimeInputWidget(
                                  label: 'Start Time',
                                  initialTime: _startTime,
                                  onTimeChanged: (time) {
                                    setState(() {
                                      _startTime = time;
                                    });
                                  },
                                ),

                                const SizedBox(height: 16),

                                TimeInputWidget(
                                  label: 'End Time',
                                  initialTime: _endTime,
                                  onTimeChanged: (time) {
                                    setState(() {
                                      _endTime = time;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),
                                ButtonWidget(
                                  text: 'Add Slot',
                                  onPressed: _addAvailabilitySlot,
                                  isLoading: _isAdding,
                                  width: double.infinity,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your Availability Slots',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your availability schedule by date',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      availabilities.isEmpty
                          ? EmptyState(
                            message: 'No availability slots added yet',
                            subMessage:
                                'Add slots above to make yourself available for appointments',
                            icon: Icons.event_busy,
                            onAction: null,
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

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    margin: const EdgeInsets.only(
                                      top: 16,
                                      bottom: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
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
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: dateAvailabilities.length,
                                    itemBuilder: (context, slotIndex) {
                                      final slot =
                                          dateAvailabilities[slotIndex];
                                      return TimeSlotWidget(
                                        availability: slot,
                                        onDelete:
                                            () => _deleteAvailabilitySlot(
                                              slot.id,
                                            ),
                                        onUpdate:
                                            (slotData) =>
                                                _updateAvailabilitySlot(
                                                  slot.id,
                                                  slotData,
                                                ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
    );
  }
}
