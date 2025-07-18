import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:campus_connect/models/availability_model.dart';
import 'package:campus_connect/config/theme.dart';

class TimeSlotWidget extends StatefulWidget {
  final AvailabilityModel availability;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onUpdate;

  const TimeSlotWidget({
    Key? key,
    required this.availability,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<TimeSlotWidget> createState() => _TimeSlotWidgetState();
}

class _TimeSlotWidgetState extends State<TimeSlotWidget> {
  bool _isEditing = false;
  late DateTime _selectedDate;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.availability.date;
    _startTimeController = TextEditingController(
      text: widget.availability.startTime,
    );
    _endTimeController = TextEditingController(
      text: widget.availability.endTime,
    );
    _isActive = widget.availability.isAvailable;
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
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

  Future<void> _showTimePickerDialog(TextEditingController controller) async {
    final timeParts = controller.text.split(':');
    final initialHour = int.tryParse(timeParts[0]) ?? 9;
    final initialMinute = int.tryParse(timeParts[1]) ?? 0;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      helpText: 'Select time (9 AM - 6 PM)',
    );

    if (pickedTime != null) {
      if (pickedTime.hour < 9 || pickedTime.hour >= 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time between 9:00 AM and 6:00 PM'),
          ),
        );
        return;
      }

      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      controller.text = '$hour:$minute';
    }
  }

  void _saveChanges() {
    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(_startTimeController.text) ||
        !timeRegex.hasMatch(_endTimeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter time in HH:MM format')),
      );
      return;
    }

    final startTimeParts = _startTimeController.text.split(':');
    final endTimeParts = _endTimeController.text.split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    if (startHour < 9 || startHour >= 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start time must be between 9:00 AM and 6:00 PM'),
        ),
      );
      return;
    }

    if (endHour < 9 || endHour > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be between 9:00 AM and 6:00 PM'),
        ),
      );
      return;
    }

    if (endHour < startHour ||
        (endHour == startHour && endMinute <= startMinute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final slotData = {
      'date': _selectedDate.toIso8601String(),
      'startTime': _startTimeController.text,
      'endTime': _endTimeController.text,
      'isActive': _isActive,
    };

    widget.onUpdate(slotData);
    setState(() {
      _isEditing = false;
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Slot'),
            content: const Text(
              'Are you sure you want to delete this time slot?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isEditing
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_formatDate(_selectedDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _selectDate(context),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('Change'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: InputDecoration(
                              labelText: 'Start Time',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
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
                            readOnly: true,
                            onTap:
                                () =>
                                    _showTimePickerDialog(_startTimeController),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: InputDecoration(
                              labelText: 'End Time',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
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
                            readOnly: true,
                            onTap:
                                () => _showTimePickerDialog(_endTimeController),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Active:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _selectedDate = widget.availability.date;
                              _startTimeController.text =
                                  widget.availability.startTime;
                              _endTimeController.text =
                                  widget.availability.endTime;
                              _isActive = widget.availability.isAvailable;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveChanges,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(widget.availability.date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.availability.startTime} - ${widget.availability.endTime}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      widget.availability.isAvailable
                                          ? AppTheme.successColor
                                          : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.availability.isAvailable
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  color:
                                      widget.availability.isAvailable
                                          ? AppTheme.successColor
                                          : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppTheme.primaryColor,
                      ),
                      tooltip: 'Edit',
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.errorColor,
                      ),
                      tooltip: 'Delete',
                      onPressed: _confirmDelete,
                    ),
                  ],
                ),
      ),
    );
  }
}
