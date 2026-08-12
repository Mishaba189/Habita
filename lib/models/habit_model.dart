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
  final List<String> completedDates;

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
    this.completedDates = const [], // Default empty list
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
      'completedDates': completedDates,
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
      completedDates: List<String>.from(map['completedDates'] ?? []),
    );
  }

  /// copyWith helper method for state immutability
  HabitModel copyWith({
    String? id,
    String? userId,
    String? goal,
    String? habitName,
    String? period,
    String? customPeriodDays,
    String? habitType,
    List<String>? specificDays,
    DateTime? createdAt,
    bool? isCompleted,
    List<String>? completedDates,
  }) {
    return HabitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goal: goal ?? this.goal,
      habitName: habitName ?? this.habitName,
      period: period ?? this.period,
      customPeriodDays: customPeriodDays ?? this.customPeriodDays,
      habitType: habitType ?? this.habitType,
      specificDays: specificDays ?? this.specificDays,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}