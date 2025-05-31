import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'staff',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}

class Task {
  final String id;
  final String clientName;
  final String natureOfEntity;
  final String natureOfWork;
  final DateTime assignDate;
  final DateTime deadline;
  final List<String> assignedStaffIds;
  final String status;
  final String? reassignmentRequest;
  final String? reassignmentReason;

  Task({
    required this.id,
    required this.clientName,
    required this.natureOfEntity,
    required this.natureOfWork,
    required this.assignDate,
    required this.deadline,
    required this.assignedStaffIds,
    this.status = 'Pending',
    this.reassignmentRequest,
    this.reassignmentReason, // 🔄
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'natureOfEntity': natureOfEntity,
      'natureOfWork': natureOfWork,
      'assignDate': assignDate.millisecondsSinceEpoch,
      'deadline': deadline.millisecondsSinceEpoch,
      'assignedStaffIds': assignedStaffIds,
      'status': status,
      'reassignmentRequest': reassignmentRequest,
      'reassignmentReason': reassignmentReason, // 🔄
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      clientName: map['clientName'] ?? '',
      natureOfEntity: map['natureOfEntity'] ?? '',
      natureOfWork: map['natureOfWork'] ?? '',
      assignDate:
          map['assignDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['assignDate'])
              : DateTime.now(),
      deadline:
          map['deadline'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['deadline'])
              : DateTime.now(),
      assignedStaffIds:
          map['assignedStaffIds'] != null
              ? List<String>.from(map['assignedStaffIds'])
              : [],
      status: map['status'] ?? 'Pending',
      reassignmentRequest: map['reassignmentRequest'],
      reassignmentReason: map['reassignmentReason'], // 🔄
    );
  }
}

class LeaveRequest {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final DateTime requestedAt;
  final String status;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.requestedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startDate': startDate,
      'endDate': endDate,
      'reason': reason,
      'requestedAt': requestedAt,
      'status': status,
    };
  }

  static LeaveRequest fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] ?? '', // Default to an empty string if id is null
      userId:
          map['userId'] ?? '', // Default to an empty string if userId is null
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      reason:
          map['reason'] ?? '', // Default to an empty string if reason is null
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      status:
          map['status'] ?? 'pending', // Default to 'pending' if status is null
    );
  }
}

class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final String? type;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'clockIn': clockIn?.millisecondsSinceEpoch,
      'clockOut': clockOut?.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final dateValue = map['date'];

    if (dateValue == null) {
      throw Exception('Missing required field "date" in attendance record');
    }

    // Convert Firestore Timestamp or milliseconds int to DateTime
    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is int) {
      date = DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else {
      throw Exception(
        'Invalid type for "date" field: ${dateValue.runtimeType}',
      );
    }

    DateTime? clockIn;
    final clockInValue = map['clockIn'];
    if (clockInValue != null) {
      if (clockInValue is Timestamp) {
        clockIn = clockInValue.toDate();
      } else if (clockInValue is int) {
        clockIn = DateTime.fromMillisecondsSinceEpoch(clockInValue);
      }
    }

    DateTime? clockOut;
    final clockOutValue = map['clockOut'];
    if (clockOutValue != null) {
      if (clockOutValue is Timestamp) {
        clockOut = clockOutValue.toDate();
      } else if (clockOutValue is int) {
        clockOut = DateTime.fromMillisecondsSinceEpoch(clockOutValue);
      }
    }

    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: date,
      clockIn: clockIn,
      clockOut: clockOut,
      type: map['type'],
    );
  }
  static AttendanceRecord? tryFromMap(Map<String, dynamic> map) {
    try {
      return AttendanceRecord.fromMap(map);
    } catch (e) {
      print('Skipping invalid attendance record: $e');
      return null;
    }
  }
}

class WaitRecord {
  final String id;
  final String staffId;
  final String staffName;
  final String clientName;
  final String fileName;
  final DateTime inWaitTime;
  final DateTime? outWaitTime;
  final bool isCompleted;
  final String? outFileName; // <-- NEW field

  WaitRecord({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.clientName,
    required this.fileName,
    required this.inWaitTime,
    this.outWaitTime,
    required this.isCompleted,
    this.outFileName, // <-- NEW field
  });

  factory WaitRecord.fromMap(Map<String, dynamic> map) {
    return WaitRecord(
      id: map['id'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      clientName: map['clientName'] ?? '',
      fileName: map['fileName'] ?? '',
      inWaitTime: (map['inWaitTime'] as Timestamp).toDate(),
      outWaitTime:
          map['outWaitTime'] != null
              ? (map['outWaitTime'] as Timestamp).toDate()
              : null,
      isCompleted: map['isCompleted'] ?? false,
      outFileName: map['outFileName'], // <-- NEW line
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'clientName': clientName,
      'fileName': fileName,
      'inWaitTime': inWaitTime,
      'outWaitTime': outWaitTime,
      'isCompleted': isCompleted,
      'outFileName': outFileName, // <-- NEW line
    };
  }
}
