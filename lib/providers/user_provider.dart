import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _listenToAuth();
    return UserState();
  }

  void _listenToAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedSeconds = prefs.getInt('premium_seconds_${user.uid}') ?? 0;
        
        _db.ref('users/${user.uid}').onValue.listen((event) {
          final data = event.snapshot.value as Map?;
          final isPermanentPro = data?['isPro'] ?? false;
          state = state.copyWith(
            uid: user.uid,
            isPro: isPermanentPro,
            premiumSecondsRemaining: savedSeconds,
          );
          _startTimer();
        });
      } else {
        _stopTimer();
        state = UserState();
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!state.isPro && state.premiumSecondsRemaining > 0) {
        final newSeconds = state.premiumSecondsRemaining - 1;
        state = state.copyWith(premiumSecondsRemaining: newSeconds);
        
        // Persist localy
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
      }
    });
  }

  void _stopTimer() {
    _countdownTimer?.cancel();
  }

  void addPremiumTime(int hours) async {
    final extraSeconds = hours * 3600;
    final newSeconds = state.premiumSecondsRemaining + extraSeconds;
    state = state.copyWith(premiumSecondsRemaining: newSeconds);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
  }

  bool get hasPremiumAccess => state.isPro || state.premiumSecondsRemaining > 0;

  Future<void> upgradeToPro() async {
    if (state.uid != null) {
      await _db.ref('users/${state.uid}').update({'isPro': true});
    }
  }

  void watchAdAndEarnHour() {
    addPremiumTime(1);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
final hasPremiumProvider = Provider((ref) => ref.watch(userProvider.notifier).hasPremiumAccess);
final premiumProgressProvider = Provider((ref) {
  final seconds = ref.watch(userProvider).premiumSecondsRemaining;
  // Progress based on 1 hour max for the bar view, or cumulative
  return (seconds % 3600) / 3600;
});
