import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

class UserState {
  final String? uid;
  final int premiumSecondsRemaining;
  final int adCooldownSeconds; // Countdown for next ad

  UserState({
    this.uid, 
    this.premiumSecondsRemaining = 0,
    this.adCooldownSeconds = 0,
  });

  UserState copyWith({
    String? uid, 
    int? premiumSecondsRemaining,
    int? adCooldownSeconds,
  }) {
    return UserState(
      uid: uid ?? this.uid,
      premiumSecondsRemaining: premiumSecondsRemaining ?? this.premiumSecondsRemaining,
      adCooldownSeconds: adCooldownSeconds ?? this.adCooldownSeconds,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _countdownTimer;
  Timer? _adTimer;

  @override
  UserState build() {
    debugPrint('[UserNotifier] 🏗️ Building UserState...');
    _loadLocalStatus();
    _listenToAuth();
    return UserState();
  }

  Future<void> _loadLocalStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt('premium_seconds_local') ?? 0;
      state = state.copyWith(premiumSecondsRemaining: seconds);
      AdService().setPremiumStatus(seconds > 0);
      if (seconds > 0) _startTimer();
    } catch (e) {
      debugPrint('[UserNotifier] ❌ Error: $e');
    }
  }

  void _listenToAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedSeconds = prefs.getInt('premium_seconds_${user.uid}') ?? state.premiumSecondsRemaining;
        state = state.copyWith(uid: user.uid, premiumSecondsRemaining: savedSeconds);
        AdService().setPremiumStatus(savedSeconds > 0);
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.premiumSecondsRemaining > 0) {
        final newSeconds = state.premiumSecondsRemaining - 1;
        state = state.copyWith(premiumSecondsRemaining: newSeconds);
        
        if (newSeconds <= 0) {
          AdService().setPremiumStatus(false);
          _countdownTimer?.cancel();
        }

        if (newSeconds % 10 == 0) {
          final prefs = await SharedPreferences.getInstance();
          if (state.uid != null) await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
          await prefs.setInt('premium_seconds_local', newSeconds);
        }
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  void startAdCooldown() {
    state = state.copyWith(adCooldownSeconds: 10);
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.adCooldownSeconds > 0) {
        state = state.copyWith(adCooldownSeconds: state.adCooldownSeconds - 1);
      } else {
        _adTimer?.cancel();
      }
    });
  }

  void addPremiumTime(int hours) async {
    final extraSeconds = hours * 3600;
    final newSeconds = state.premiumSecondsRemaining + extraSeconds;
    state = state.copyWith(premiumSecondsRemaining: newSeconds);
    
    final prefs = await SharedPreferences.getInstance();
    if (state.uid != null) await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
    await prefs.setInt('premium_seconds_local', newSeconds);
    
    AdService().setPremiumStatus(true);
    _startTimer();
    startAdCooldown(); // Start cooldown after watching an ad
  }

  bool get hasPremiumAccess => state.premiumSecondsRemaining > 0;

  void watchAdAndEarnHour() {
    addPremiumTime(1);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
final hasPremiumProvider = Provider((ref) => ref.watch(userProvider.notifier).hasPremiumAccess);

final premiumProgressProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  return (user.premiumSecondsRemaining % 3600) / 3600;
});
