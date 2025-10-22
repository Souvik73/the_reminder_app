import 'package:equatable/equatable.dart';

class SubscriptionState extends Equatable {
  final bool isPremium;

  const SubscriptionState({required this.isPremium});

  factory SubscriptionState.initial() =>
      const SubscriptionState(isPremium: false);

  SubscriptionState copyWith({bool? isPremium}) {
    return SubscriptionState(isPremium: isPremium ?? this.isPremium);
  }

  @override
  List<Object?> get props => [isPremium];
}
