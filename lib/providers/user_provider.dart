import 'dart:async';
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
    _loadLocalStatus();
    _listenToAuth();
    return UserState();
  }

  Future<void> _loadLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro_permanent') ?? false;
    final seconds = prefs.getInt('premium_seconds_local') ?? 0;
    state = state.copyWith(isPro: isPro, premiumSecondsRemaining: seconds);
    if (seconds > 0) _startTimer();
  }

  void _listenToAuth() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final savedSeconds = prefs.getInt('premium_seconds_${user.uid}') ?? state.premiumSecondsRemaining;
        
        _db.ref('users/${user.uid}').onValue.listen((event) async {
          final data = event.snapshot.value as Map?;
          final isPermanentPro = data?['isPro'] ?? false;
          
          state = state.copyWith(
            uid: user.uid,
            isPro: isPermanentPro,
            premiumSecondsRemaining: savedSeconds,
          );

          // Sync to local
          await prefs.setBool('is_pro_permanent', isPermanentPro);
          _startTimer();
        });
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!state.isPro && state.premiumSecondsRemaining > 0) {
        final newSeconds = state.premiumSecondsRemaining - 1;
        state = state.copyWith(premiumSecondsRemaining: newSeconds);
        
        final prefs = await SharedPreferences.getInstance();
        if (state.uid != null) {
          await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
        }
        await prefs.setInt('premium_seconds_local', newSeconds);
      } else if (state.premiumSecondsRemaining <= 0) {
        _countdownTimer?.cancel();
      }
    });
  }

  void addPremiumTime(int hours) async {
    final extraSeconds = hours * 3600;
    final newSeconds = state.premiumSecondsRemaining + extraSeconds;
    state = state.copyWith(premiumSecondsRemaining: newSeconds);
    
    final prefs = await SharedPreferences.getInstance();
    if (state.uid != null) {
      await prefs.setInt('premium_seconds_${state.uid}', newSeconds);
    }
    await prefs.setInt('premium_seconds_local', newSeconds);
    _startTimer();
  }

  bool get hasPremiumAccess => state.isPro || state.premiumSecondsRemaining > 0;

  Future<void> upgradeToPro() async {
    state = state.copyWith(isPro: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_permanent', true);
    
    // Sync with AdService
    AdService().setPremiumStatus(true);
    
    if (state.uid != null) {
      await _db.ref('users/${state.uid}').update({'isPro': true});
    }
  }

  void watchAdAndEarnHour() {
    addPremiumTime(1);
    // Ad earned time, so ads should be disabled for at least an hour
    AdService().setPremiumStatus(true);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
final hasPremiumProvider = Provider((ref) => ref.watch(userProvider.notifier).hasPremiumAccess);

final premiumProgressProvider = Provider((ref) {
  final user = ref.watch(userProvider);
  if (user.isPro) return 1.0;
  return (user.premiumSecondsRemaining % 3600) / 3600;
});
