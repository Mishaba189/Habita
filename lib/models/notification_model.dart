import 'package:cloud_firestore/cloud_firestore.dart';


class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String status;
  final bool isSuccess;
  final bool isRead;
  final DateTime createdAt;
  final String? habitId; // Add field

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.isSuccess,
    this.isRead = false,
    required this.createdAt,
    this.habitId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'status': status,
      'isSuccess': isSuccess,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      if (habitId != null) 'habitId': habitId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? '',
      isSuccess: map['isSuccess'] ?? true,
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      habitId: map['habitId'] as String?,
    );
  }
}