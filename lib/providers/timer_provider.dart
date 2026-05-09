import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_provider.dart';

class TimerState {
  final int? remainingSeconds;
  final bool isActive;

  TimerState({this.remainingSeconds, this.isActive = false});
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() => _timer?.cancel());
    return TimerState();
  }

  void setTimer(int minutes) {
    _timer?.cancel();
    final seconds = minutes * 60;
    state = TimerState(remainingSeconds: seconds, isActive: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds == null || state.remainingSeconds! <= 0) {
        timer.cancel();
        state = TimerState(remainingSeconds: 0, isActive: false);
        ref.read(audioProvider.notifier).stopAll();
      } else {
        state = TimerState(remainingSeconds: state.remainingSeconds! - 1, isActive: true);
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    state = TimerState(remainingSeconds: null, isActive: false);
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
