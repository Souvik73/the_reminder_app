import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionState extends Equatable {
  final bool isPremium;
  final bool isLoading;
  final bool isProcessing;
  final bool isSupportedPlatform;
  final bool hasApiKey;
  final List<Package> packages;
  final String? errorMessage;

  const SubscriptionState({
    required this.isPremium,
    required this.isLoading,
    required this.isProcessing,
    required this.isSupportedPlatform,
    required this.hasApiKey,
    required this.packages,
    required this.errorMessage,
  });

  factory SubscriptionState.initial() => const SubscriptionState(
        isPremium: false,
        isLoading: false,
        isProcessing: false,
        isSupportedPlatform: true,
        hasApiKey: true,
        packages: <Package>[],
        errorMessage: null,
      );

  SubscriptionState copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? isProcessing,
    bool? isSupportedPlatform,
    bool? hasApiKey,
    List<Package>? packages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      isSupportedPlatform: isSupportedPlatform ?? this.isSupportedPlatform,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      packages: packages ?? this.packages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isPremium,
        isLoading,
        isProcessing,
        isSupportedPlatform,
        hasApiKey,
        packages,
        errorMessage,
      ];
}
