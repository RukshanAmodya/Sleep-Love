import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ad_service.dart';

class UserState {
  final String? uid;
  final bool isPro;
  final int premiumSecondsRemaining;

  UserState({this.uid, this.isPro = false, this.premiumSecondsRemaining = 0});

  UserState copyWith({String? uid, bool? isPro, int? premiumSecondsRemaining}) {
    return UserState(
      uid: uid ?? this.uid,
      isPro: isPro ?? this.isPro,
      premiumSecondsRemaining: premiumSecondsRemaining ?? this.premiumSecondsRemaining,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  Timer? _countdownTimer;

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
      final isPro = prefs.getBool('is_pro_permanent') ?? false;
      final seconds = prefs.getInt('premium_seconds_local') ?? 0;
      
      debugPrint('[UserNotifier] 📦 Loaded Local Status: isPro=$isPro, seconds=$seconds');
      
      state = state.copyWith(isPro: isPro, premiumSecondsRemaining: seconds);
      
      // Update AdService immediately
      AdService().setPremiumStatus(isPro || seconds > 0);
      
      if (seconds > 0) _startTimer();
    } catch (e) {
      debugPrint('[UserNotifier] ❌ Error loading local status: $e');
    }
  }

  void _listenToAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint('[UserNotifier] 🔑 User Logged In: ${user.uid}');
        final prefs = await SharedPreferences.getInstance();
        final savedSeconds = prefs.getInt('premium_seconds_${user.uid}') ?? state.premiumSecondsRemaining;
        
        _db.ref('users/${user.uid}').onValue.listen((event) async {
          final data = event.snapshot.value as Map?;
          final isPermanentPro = data?['isPro'] ?? false;
          
          debugPrint('[UserNotifier] ☁️ Firebase Update: isPro=$isPermanentPro');
          
          state = state.copyWith(
            uid: user.uid,
            isPro: isPermanentPro,
            premiumSecondsRemaining: savedSeconds,
          );

          // Sync to local
          await prefs.setBool('is_pro_permanent', isPermanentPro);
          AdService().setPremiumStatus(isPermanentPro || savedSeconds > 0);
          _startTimer();
        });
      } else {
        debugPrint('[UserNotifier] 🚪 User Logged Out or Anonymous');
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!state.isPro && state.premiumSecondsRemaining > 0) {
        final newSeconds = state.premiumSecondsRemaining - 1;
        state = state.copyWith(premiumSecondsRemaining: newSeconds);
        
        if (newSeconds <= 0) {
          debugPrint('[UserNotifier] ⏰ Premium Time Expired!');
          AdService().setPremiumStatus(state.isPro); // Re-sync with AdService
          _countdownTimer?.cancel();
        }

        // Persist localy every 10 seconds to avoid too many writes
        if (newSeconds % 10 == 0) {
          final prefs = await SharedPreferences.getInstance();
          if (state.uid != null) {
            await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
          }
          await prefs.setInt('premium_seconds_local', newSeconds);
        }
      } else if (state.isPro) {
        _countdownTimer?.cancel();
      }
    });
  }

  void addPremiumTime(int hours) async {
    final extraSeconds = hours * 3600;
    final newSeconds = state.premiumSecondsRemaining + extraSeconds;
    debugPrint('[UserNotifier] ➕ Adding $hours hours ($extraSeconds seconds). New total: $newSeconds');
    
    state = state.copyWith(premiumSecondsRemaining: newSeconds);
    
    final prefs = await SharedPreferences.getInstance();
    if (state.uid != null) {
      await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
    }
    await prefs.setInt('premium_seconds_local', newSeconds);
    
    AdService().setPremiumStatus(true);
    _startTimer();
  }

  bool get hasPremiumAccess {
    final access = state.isPro || state.premiumSecondsRemaining > 0;
    // debugPrint('[UserNotifier] 🔍 Access Check: $access (isPro=${state.isPro}, seconds=${state.premiumSecondsRemaining})');
    return access;
  }

  Future<void> upgradeToPro() async {
    debugPrint('[UserNotifier] 💎 Upgrading to Pro Permanently...');
    state = state.copyWith(isPro: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_permanent', true);
    
    AdService().setPremiumStatus(true);
    
    if (state.uid != null) {
      await _db.ref('users/${state.uid}').update({'isPro': true});
    }
  }

  void watchAdAndEarnHour() {
    debugPrint('[UserNotifier] 📺 Ad Watched — Rewarding 1 hour');
    addPremiumTime(1);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
final hasPremiumProvider = Provider((ref) => ref.watch(userProvider.notifier).hasPremiumAccess);

final premiumProgressProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  if (user.isPro) return 1.0;
  return (user.premiumSecondsRemaining % 3600) / 3600;
});
