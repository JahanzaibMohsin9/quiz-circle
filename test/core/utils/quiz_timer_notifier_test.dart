import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_circle/core/utils/quiz_timer.dart';

void main() {
  group('QuizTimerNotifier', () {
    test('initialize, start, pause, reset update state flags', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(quizTimerProvider);
      expect(state.totalSeconds, 0);
      expect(state.isRunning, false);

      final notifier = container.read(quizTimerProvider.notifier);
      int lastTick = -1;
      bool timeUpCalled = false;

      notifier.initializeTimer(
        totalSeconds: 3,
        onTick: (s) => lastTick = s,
        onTimeUp: () => timeUpCalled = true,
      );

      var s = container.read(quizTimerProvider);
      expect(s.totalSeconds, 3);
      expect(s.remainingSeconds, 3);

      notifier.startTimer();
      s = container.read(quizTimerProvider);
      expect(s.isRunning, true);
      expect(s.isTimeUp, false);

      notifier.pauseTimer();
      s = container.read(quizTimerProvider);
      expect(s.isRunning, false);

      notifier.resetTimer();
      s = container.read(quizTimerProvider);
      expect(s.isRunning, false);
      expect(s.isTimeUp, false);
      expect(s.remainingSeconds, 3);

      expect(lastTick, isA<int>());
      expect(timeUpCalled, isFalse);
    });
  });
}
