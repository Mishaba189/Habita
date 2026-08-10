import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String? id;
  final String userId;
  final String goal;
  final String habitName;
  final String period;
  final String? customPeriodDays;
  final String habitType;
  final List<String> specificDays;
  final DateTime createdAt;
  final bool isCompleted;

  HabitModel({
    this.id,
    required this.userId,
    required this.goal,
    required this.habitName,
    required this.period,
    this.customPeriodDays,
    required this.habitType,
    required this.specificDays,
    required this.createdAt,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'goal': goal,
      'habitName': habitName,
      'period': period,
      'customPeriodDays': customPeriodDays,
      'habitType': habitType,
      'specificDays': specificDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'isCompleted': isCompleted,
    };
  }

  factory HabitModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HabitModel(
      id: documentId,
      userId: map['userId'] ?? '',
      goal: map['goal'] ?? '',
      habitName: map['habitName'] ?? '',
      period: map['period'] ?? '',
      customPeriodDays: map['customPeriodDays'],
      habitType: map['habitType'] ?? '',
      specificDays: List<String>.from(map['specificDays'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}