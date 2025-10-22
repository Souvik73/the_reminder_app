import 'package:equatable/equatable.dart';
import 'package:the_reminder_app/models/planner_models.dart';

class HydrationState extends Equatable {
  final int dailyGoal;
  final List<HydrationLog> logs;
  final String activeUserId;
  final bool isLoading;

  const HydrationState({
    required this.dailyGoal,
    required this.logs,
    required this.activeUserId,
    required this.isLoading,
  });

  factory HydrationState.initial({required String userId}) {
    return HydrationState(
      dailyGoal: 2500,
      logs: const [],
      activeUserId: userId,
      isLoading: true,
    );
  }

  HydrationState copyWith({
    int? dailyGoal,
    List<HydrationLog>? logs,
    String? activeUserId,
    bool? isLoading,
  }) {
    return HydrationState(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      logs: logs ?? this.logs,
      activeUserId: activeUserId ?? this.activeUserId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  int get totalIntake => logs.fold<int>(0, (total, log) => total + log.amount);

  @override
  List<Object?> get props => [dailyGoal, logs, activeUserId, isLoading];
}
