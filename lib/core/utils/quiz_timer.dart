import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizTimer {
  Timer? _timer;
  int _remainingSeconds = 0;
  final void Function(int) onTick;
  final void Function() onTimeUp;

  QuizTimer({
    required this.onTick,
    required this.onTimeUp,
  });

  void start(int totalSeconds) {
    _remainingSeconds = totalSeconds;
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        onTick(_remainingSeconds);
      } else {
        stop();
        onTimeUp();
      }
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    stop();
    _remainingSeconds = 0;
  }

  bool get isRunning => _timer?.isActive ?? false;
  
  int get remainingSeconds => _remainingSeconds;
}

class QuizTimerNotifier extends Notifier<QuizTimerState> {
  @override
  QuizTimerState build() {
    return const QuizTimerState();
  }

  late QuizTimer _timer;

  void initializeTimer({
    required int totalSeconds,
    int? initialRemaining,
    required void Function(int) onTick,
    required void Function() onTimeUp,
  }) {
    _timer = QuizTimer(
      onTick: (seconds) {
        state = state.copyWith(remainingSeconds: seconds);
        onTick(seconds);
      },
      onTimeUp: () {
        state = state.copyWith(isTimeUp: true, isRunning: false);
        onTimeUp();
      },
    );
    
    state = state.copyWith(
      totalSeconds: totalSeconds,
      remainingSeconds: initialRemaining ?? totalSeconds,
    );
  }

  void startTimer() {
    if (state.remainingSeconds > 0) {
      _timer.start(state.remainingSeconds);
      state = state.copyWith(isRunning: true, isTimeUp: false);
    }
  }

  void pauseTimer() {
    _timer.pause();
    state = state.copyWith(isRunning: false);
  }

  void stopTimer() {
    _timer.stop();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer.reset();
    state = state.copyWith(
      isRunning: false,
      isTimeUp: false,
      remainingSeconds: state.totalSeconds,
    );
  }

  void dispose() {
    _timer.stop();
  }
}

class QuizTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isTimeUp;

  const QuizTimerState({
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.isTimeUp = false,
  });

  QuizTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isTimeUp,
  }) {
    return QuizTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isTimeUp: isTimeUp ?? this.isTimeUp,
    );
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progressPercentage {
    if (totalSeconds <= 0) return 0.0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }
}

final quizTimerProvider = NotifierProvider<QuizTimerNotifier, QuizTimerState>(() {
  return QuizTimerNotifier();
});