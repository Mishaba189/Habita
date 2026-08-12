import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String? id;
  final String userId;
  final String goalTitle;
  final String period;
  final String? customPeriodDays;
  final DateTime createdAt;

  GoalModel({
    this.id,
    required this.userId,
    required this.goalTitle,
    required this.period,
    this.customPeriodDays,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goalTitle': goalTitle,
      'period': period,
      'customPeriodDays': customPeriodDays,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, String docId) {
    return GoalModel(
      id: docId,
      userId: map['userId'] ?? '',
      goalTitle: map['goalTitle'] ?? '',
      period: map['period'] ?? '',
      customPeriodDays: map['customPeriodDays'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}