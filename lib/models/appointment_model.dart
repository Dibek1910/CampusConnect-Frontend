class AppointmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String facultyId;
  final String facultyName;
  final String? availabilityId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int? duration;
  final String purpose;
  final String purposeCategory;
  final String? customPurposeText;
  final String status;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDirectRequest;

  AppointmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.facultyId,
    required this.facultyName,
    this.availabilityId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.duration,
    required this.purpose,
    required this.purposeCategory,
    this.customPurposeText,
    required this.status,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    this.isDirectRequest = false,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    print('Parsing appointment JSON: $json');

    String id = '';
    if (json.containsKey('_id')) {
      id = json['_id'] ?? '';
    } else if (json.containsKey('id')) {
      id = json['id'] ?? '';
    }

    String studentId = '';
    String studentName = '';
    if (json.containsKey('student')) {
      if (json['student'] is Map) {
        studentId = json['student']['_id'] ?? '';
        studentName = json['student']['name'] ?? '';
      } else {
        studentId = json['student'] ?? '';
      }
    } else {
      studentId = json['studentId'] ?? '';
      studentName = json['studentName'] ?? '';
    }

    String facultyId = '';
    String facultyName = '';
    if (json.containsKey('faculty')) {
      if (json['faculty'] is Map) {
        facultyId = json['faculty']['_id'] ?? '';
        facultyName = json['faculty']['name'] ?? '';
      } else {
        facultyId = json['faculty'] ?? '';
      }
    } else {
      facultyId = json['facultyId'] ?? '';
      facultyName = json['facultyName'] ?? '';
    }

    String? availabilityId;
    if (json.containsKey('availability')) {
      if (json['availability'] is Map) {
        availabilityId = json['availability']['_id'] ?? '';
      } else if (json['availability'] != null) {
        availabilityId = json['availability'] ?? '';
      }
    } else if (json.containsKey('availabilityId') &&
        json['availabilityId'] != null) {
      availabilityId = json['availabilityId'];
    }

    DateTime date;
    try {
      date =
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now();
    } catch (e) {
      print('Error parsing date: $e');
      date = DateTime.now();
    }

    int? duration;
    if (json['duration'] != null) {
      duration = int.tryParse(json['duration'].toString());
    }

    String purposeCategory = 'Other';
    if (json['purposeCategory'] != null) {
      purposeCategory = json['purposeCategory'];
    } else if (json['purpose'] != null) {
      purposeCategory = 'Other';
    }

    return AppointmentModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      facultyId: facultyId,
      facultyName: facultyName,
      availabilityId: availabilityId,
      date: date,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      duration: duration,
      purpose: json['purpose'] ?? '',
      purposeCategory: purposeCategory,
      customPurposeText: json['customPurposeText'],
      status: json['status'] ?? 'pending',
      cancelReason: json['cancelReason'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      isDirectRequest: json['isDirectRequest'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'studentId': studentId,
      'studentName': studentName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'purpose': purpose,
      'purposeCategory': purposeCategory,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDirectRequest': isDirectRequest,
    };

    if (availabilityId != null) {
      data['availabilityId'] = availabilityId;
    }
    if (duration != null) {
      data['duration'] = duration;
    }
    if (customPurposeText != null) {
      data['customPurposeText'] = customPurposeText;
    }
    if (cancelReason != null) {
      data['cancelReason'] = cancelReason;
    }

    return data;
  }
}
