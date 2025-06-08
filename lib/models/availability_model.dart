class AvailabilityModel {
  final String id;
  final String facultyId;
  final DateTime date;
  final String day;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  AvailabilityModel({
    required this.id,
    required this.facultyId,
    required this.date,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    print('Parsing availability JSON: $json');

    String id = '';
    if (json.containsKey('_id')) {
      id = json['_id'] ?? '';
    } else if (json.containsKey('id')) {
      id = json['id'] ?? '';
    }

    String facultyId = '';
    if (json.containsKey('faculty')) {
      if (json['faculty'] is Map) {
        facultyId = json['faculty']['_id'] ?? '';
      } else {
        facultyId = json['faculty'] ?? '';
      }
    } else if (json.containsKey('facultyId')) {
      facultyId = json['facultyId'] ?? '';
    }

    // Parse date
    DateTime date;
    try {
      date =
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    } catch (e) {
      print('Error parsing date: $e');
      date = DateTime.now();
    }

    String day = json['day'] ?? '';
    if (day.isNotEmpty) {
      day = day[0].toUpperCase() + day.substring(1).toLowerCase();
    }

    bool isAvailable = true;
    if (json.containsKey('isBooked')) {
      isAvailable = !(json['isBooked'] ?? false);
    }
    if (json.containsKey('isActive')) {
      isAvailable = isAvailable && (json['isActive'] ?? true);
    }
    if (json.containsKey('isAvailable')) {
      isAvailable = json['isAvailable'] ?? true;
    }

    return AvailabilityModel(
      id: id,
      facultyId: facultyId,
      date: date,
      day: day,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: isAvailable,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'facultyId': facultyId,
      'date': date.toIso8601String(),
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
