import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../providers/focus_provider.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(focusTimerProvider);
    final sessions = ref.watch(focusSessionsProvider);
    final totalMinutes = ref.watch(totalFocusMinutesProvider);
    final theme = Theme.of(context);

    final isActive = timer.state == FocusState.focusing ||
        timer.state == FocusState.onBreak ||
        timer.state == FocusState.paused;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Focus', style: theme.textTheme.titleLarge),
                        if (!isActive)
                          IconButton(
                            onPressed: () => _showSettings(context, ref, timer),
                            icon: const Icon(Icons.tune_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildTimerRing(context, theme, timer),
                    const SizedBox(height: 16),
                    _buildStateLabel(theme, timer),
                    const SizedBox(height: 32),
                    _buildControls(context, ref, timer),
                    const SizedBox(height: 32),
                    if (timer.sessionsCompleted > 0 || sessions.isNotEmpty) ...[
                      _buildSessionStats(context, theme, timer, totalMinutes),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            if (sessions.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent sessions',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final s = sessions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionTile(session: s, theme: theme),
                      );
                    },
                    childCount: sessions.take(5).length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerRing(
      BuildContext context, ThemeData theme, FocusTimerData timer) {
    final Color ringColor = timer.state == FocusState.onBreak
        ? AppTheme.success
        : AppTheme.primary;

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(240, 240),
            painter: _TimerRingPainter(
              progress: timer.progress,
              color: ringColor,
              strokeWidth: 10,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timer.formattedTime,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timer.state == FocusState.onBreak ? 'Break' : 'Focus',
                style: TextStyle(
                  color: ringColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateLabel(ThemeData theme, FocusTimerData timer) {
    String message;
    switch (timer.state) {
      case FocusState.idle:
        message = 'Ready to focus?';
        break;
      case FocusState.focusing:
        message = 'Stay in the zone 🎯';
        break;
      case FocusState.onBreak:
        message = 'Rest up, break time ☕';
        break;
      case FocusState.paused:
        message = 'Session paused';
        break;
    }
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, WidgetRef ref, FocusTimerData timer) {
    final notifier = ref.read(focusTimerProvider.notifier);

    if (timer.state == FocusState.idle) {
      return ElevatedButton.icon(
        onPressed: notifier.start,
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text('Start Focus'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            notifier.stop();
          },
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Stop'),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            side: const BorderSide(color: AppTheme.danger),
            foregroundColor: AppTheme.danger,
          ),
        ),
        const SizedBox(width: 16),
        if (timer.state == FocusState.paused)
          ElevatedButton.icon(
            onPressed: notifier.resume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          )
        else if (timer.state == FocusState.focusing)
          ElevatedButton.icon(
            onPressed: notifier.pause,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionStats(BuildContext context, ThemeData theme,
      FocusTimerData timer, int totalMinutes) {
    return Row(
      children: [
        _StatCard(
          icon: '🎯',
          label: 'Sessions today',
          value: '${timer.sessionsCompleted}',
          theme: theme,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: '⏱️',
          label: 'Total focus time',
          value: AppUtils.formatDuration(totalMinutes),
          theme: theme,
        ),
      ],
    );
  }

  void _showSettings(
      BuildContext context, WidgetRef ref, FocusTimerData timer) {
    int focusMin = timer.focusMinutes;
    int breakMin = timer.breakMinutes;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Timer Settings',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Focus duration',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: focusMin > 5
                              ? () => setModalState(
                                  () => focusMin -= 5)
                              : null,
                        ),
                        Text('${focusMin}m',
                            style: Theme.of(context).textTheme.titleSmall),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: focusMin < 60
                              ? () => setModalState(() => focusMin += 5)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Break duration',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: breakMin > 1
                              ? () => setModalState(() => breakMin -= 1)
                              : null,
                        ),
                        Text('${breakMin}m',
                            style: Theme.of(context).textTheme.titleSmall),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: breakMin < 30
                              ? () => setModalState(() => breakMin += 1)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(focusTimerProvider.notifier)
                          .setDurations(focusMin, breakMin);
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium,
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final session;
  final ThemeData theme;

  const _SessionTile({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_rounded,
                size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.durationMinutes} min session',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  AppUtils.formatDateTime(session.completedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (session.wasCompleted)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  color: AppTheme.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}
