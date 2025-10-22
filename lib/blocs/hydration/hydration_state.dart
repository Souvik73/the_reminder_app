import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class HydrationState extends Equatable {
  final int dailyGoal;
  final List<HydrationLog> logs;

  const HydrationState({
    required this.dailyGoal,
    required this.logs,
  });

  factory HydrationState.initial() {
    final now = DateTime.now();
    return HydrationState(
      dailyGoal: 2500,
      logs: [
        HydrationLog(id: 'h1', amount: 400, timestamp: now.subtract(const Duration(hours: 2))),
        HydrationLog(id: 'h2', amount: 250, timestamp: now.subtract(const Duration(hours: 5))),
        HydrationLog(id: 'h3', amount: 300, timestamp: now.subtract(const Duration(hours: 9))),
      ],
    );
  }

  HydrationState copyWith({
    int? dailyGoal,
    List<HydrationLog>? logs,
  }) {
    return HydrationState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      logs: logs ?? this.logs,
    );
  }

  int get totalIntake => logs.fold<int>(0, (total, log) => total + log.amount);

  @override
  List<Object?> get props => [dailyGoal, logs];
}
