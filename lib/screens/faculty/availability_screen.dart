import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/providers/availability_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/time_slot_widget.dart';
import 'package:campus_connect/widgets/loading_indicator.dart';
import 'package:campus_connect/widgets/error_display.dart';
import 'package:campus_connect/widgets/empty_state.dart';
import 'package:campus_connect/config/theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({Key? key}) : super(key: key);

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
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

    // Set default date to next weekday if today is weekend
    _setDefaultDate();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailabilities();
    });
  }

  void _setDefaultDate() {
    final now = DateTime.now();
    if (now.weekday > 5) {
      // If weekend, set to next Monday
      _selectedDate = now.add(Duration(days: 8 - now.weekday));
    } else {
      _selectedDate = now;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
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
        // Only allow weekdays (Monday = 1, Friday = 5)
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
    if (_startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
      _showSnackBar('Please enter both start and end time');
      return;
    }

    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(_startTimeController.text) ||
        !timeRegex.hasMatch(_endTimeController.text)) {
      _showSnackBar('Please enter time in HH:MM format');
      return;
    }

    final startTimeParts = _startTimeController.text.split(':');
    final endTimeParts = _endTimeController.text.split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    // Validate time range (9 AM to 6 PM)
    if (startHour < 9 ||
        startHour >= 18 ||
        (startHour == 18 && startMinute > 0)) {
      _showSnackBar('Start time must be between 9:00 AM and 6:00 PM');
      return;
    }

    if (endHour < 9 || endHour > 18 || (endHour == 18 && endMinute > 0)) {
      _showSnackBar('End time must be between 9:00 AM and 6:00 PM');
      return;
    }

    if (endHour < startHour ||
        (endHour == startHour && endMinute <= startMinute)) {
      _showSnackBar('End time must be after start time');
      return;
    }

    // Check if the time is not in the past for today's date
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
      'startTime': _startTimeController.text,
      'endTime': _endTimeController.text,
    };

    final success = await availabilityProvider.addAvailabilitySlot(slotData);

    setState(() {
      _isAdding = false;
    });

    if (success) {
      _startTimeController.clear();
      _endTimeController.clear();
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

  Future<void> _showTimePickerDialog(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      helpText: 'Select time (9 AM - 6 PM)',
    );

    if (pickedTime != null) {
      // Validate time range
      if (pickedTime.hour < 9 || pickedTime.hour >= 18) {
        _showSnackBar('Please select a time between 9:00 AM and 6:00 PM');
        return;
      }

      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      controller.text = '$hour:$minute';
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

    // Group availabilities by date
    Map<String, List<AvailabilityModel>> availabilitiesByDate = {};

    for (var availability in availabilities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(availability.date);
      if (!availabilitiesByDate.containsKey(dateKey)) {
        availabilitiesByDate[dateKey] = [];
      }
      availabilitiesByDate[dateKey]!.add(availability);
    }

    // Sort dates
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

                                // Date Selection
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

                                const SizedBox(height: 16),

                                // Time Selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _startTimeController,
                                        decoration: InputDecoration(
                                          labelText: 'Start Time (9 AM - 6 PM)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.access_time),
                                            onPressed:
                                                () => _showTimePickerDialog(
                                                  _startTimeController,
                                                ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.datetime,
                                        readOnly: true,
                                        onTap:
                                            () => _showTimePickerDialog(
                                              _startTimeController,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _endTimeController,
                                        decoration: InputDecoration(
                                          labelText: 'End Time (9 AM - 6 PM)',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.access_time),
                                            onPressed:
                                                () => _showTimePickerDialog(
                                                  _endTimeController,
                                                ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.datetime,
                                        readOnly: true,
                                        onTap:
                                            () => _showTimePickerDialog(
                                              _endTimeController,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
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
