import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/focus_session_model.dart';
import '../../../services/database_service.dart';

enum FocusState { idle, focusing, onBreak, paused }

class FocusTimerData {
  final FocusState state;
  final int remainingSeconds;
  final int totalSeconds;
  final int sessionsCompleted;
  final int focusMinutes;
  final int breakMinutes;

  const FocusTimerData({
    this.state = FocusState.idle,
    this.remainingSeconds = 25 * 60,
    this.totalSeconds = 25 * 60,
    this.sessionsCompleted = 0,
    this.focusMinutes = 25,
    this.breakMinutes = 5,
  });

  FocusTimerData copyWith({
    FocusState? state,
    int? remainingSeconds,
    int? totalSeconds,
    int? sessionsCompleted,
    int? focusMinutes,
    int? breakMinutes,
  }) =>
      FocusTimerData(
        state: state ?? this.state,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
      );

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 0;

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class FocusTimerNotifier extends StateNotifier<FocusTimerData> {
  FocusTimerNotifier() : super(const FocusTimerData());

  Timer? _timer;

  void start() {
    _timer?.cancel();
    state = state.copyWith(
      state: FocusState.focusing,
      remainingSeconds: state.focusMinutes * 60,
      totalSeconds: state.focusMinutes * 60,
    );
    _startCountdown();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(state: FocusState.paused);
  }

  void resume() {
    state = state.copyWith(state: FocusState.focusing);
    _startCountdown();
  }

  void stop() {
    _timer?.cancel();
    state = const FocusTimerData();
  }

  void setDurations(int focusMin, int breakMin) {
    state = state.copyWith(
      focusMinutes: focusMin,
      breakMinutes: breakMin,
      remainingSeconds: focusMin * 60,
      totalSeconds: focusMin * 60,
    );
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        _sessionComplete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  Future<void> _sessionComplete() async {
    if (state.state == FocusState.focusing) {
      // Save focus session
      final session = FocusSessionModel(
        durationMinutes: state.focusMinutes,
        wasCompleted: true,
      );
      await DatabaseService.focusSessionsBox.put(session.id, session);

      state = state.copyWith(
        state: FocusState.onBreak,
        remainingSeconds: state.breakMinutes * 60,
        totalSeconds: state.breakMinutes * 60,
        sessionsCompleted: state.sessionsCompleted + 1,
      );
      _startCountdown();
    } else if (state.state == FocusState.onBreak) {
      // Break done, reset to idle
      state = FocusTimerData(
        focusMinutes: state.focusMinutes,
        breakMinutes: state.breakMinutes,
        sessionsCompleted: state.sessionsCompleted,
        remainingSeconds: state.focusMinutes * 60,
        totalSeconds: state.focusMinutes * 60,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerData>((ref) {
  return FocusTimerNotifier();
});

// Focus session history provider
final focusSessionsProvider = Provider<List<FocusSessionModel>>((ref) {
  final box = DatabaseService.focusSessionsBox;
  return box.values.toList()
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
});

final totalFocusMinutesProvider = Provider<int>((ref) {
  final sessions = ref.watch(focusSessionsProvider);
  return sessions.fold(0, (sum, s) => sum + s.durationMinutes);
});
