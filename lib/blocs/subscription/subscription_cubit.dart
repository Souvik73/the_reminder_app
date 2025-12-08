import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:the_reminder_app/blocs/subscription/subscription_state.dart';
import 'package:the_reminder_app/services/purchase_service.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({required PurchaseService purchaseService})
      : _purchaseService = purchaseService,
        super(SubscriptionState.initial());

  final PurchaseService _purchaseService;
  StreamSubscription<bool>? _premiumSubscription;
  bool _bootstrapped = false;

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    emit(
      state.copyWith(
        isLoading: true,
        isSupportedPlatform: _purchaseService.isSupportedPlatform,
        hasApiKey: _purchaseService.hasApiKey,
        clearError: true,
      ),
    );

    await _purchaseService.init();
    _premiumSubscription = _purchaseService.premiumStream.listen((isPremium) {
      emit(
        state.copyWith(
          isPremium: isPremium,
          clearError: true,
        ),
      );
    });

    await _purchaseService.refreshCustomerInfo();
    final packages = await _purchaseService.loadPackages();

    emit(
      state.copyWith(
        isPremium: _purchaseService.isPremium,
        packages: packages,
        isSupportedPlatform: _purchaseService.isSupportedPlatform,
        hasApiKey: _purchaseService.hasApiKey,
        isLoading: false,
        errorMessage: _purchaseService.lastError,
      ),
    );
  }

  Future<void> loadPackages() async {
    if (state.isLoading) return;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );
    final packages = await _purchaseService.loadPackages();
    emit(
      state.copyWith(
        packages: packages,
        isLoading: false,
        errorMessage: _purchaseService.lastError,
      ),
    );
  }

  Future<void> purchase(Package package) async {
    emit(
      state.copyWith(
        isProcessing: true,
        clearError: true,
      ),
    );
    try {
      await _purchaseService.purchase(package);
    } on PlatformException catch (err) {
      final code = PurchasesErrorHelper.getErrorCode(err);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        emit(state.copyWith(isProcessing: false));
        return;
      }
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: err.message ?? 'Purchase failed.',
        ),
      );
      return;
    } catch (err) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: err.toString(),
        ),
      );
      return;
    }
    await _refreshState();
  }

  Future<void> restore() async {
    emit(
      state.copyWith(
        isProcessing: true,
        clearError: true,
      ),
    );
    try {
      await _purchaseService.restore();
    } on PlatformException catch (err) {
      final code = PurchasesErrorHelper.getErrorCode(err);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        emit(state.copyWith(isProcessing: false));
        return;
      }
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: err.message ?? 'Restore failed.',
        ),
      );
      return;
    } catch (err) {
      emit(
        state.copyWith(
          isProcessing: false,
          errorMessage: err.toString(),
        ),
      );
      return;
    }
    await _refreshState();
  }

  Future<void> _refreshState() async {
    await _purchaseService.refreshCustomerInfo();
    emit(
      state.copyWith(
        isPremium: _purchaseService.isPremium,
        isProcessing: false,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _premiumSubscription?.cancel();
    return super.close();
  }
}
