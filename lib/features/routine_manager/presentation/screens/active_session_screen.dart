import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/active_session_controller.dart';
import '../controllers/routine_list_controller.dart';
import '../../domain/entities/active_session.dart';
import '../../../../core/theme/app_theme.dart';

/// Active Session Screen - Primary execution interface for a running routine.
/// // Fulfills INT-03, INT-05, INT-06, INT-11
class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeSessionControllerProvider);
    final routines = ref.watch(routineListProvider).value ?? [];
    
    // Inactive or missing data safety
    if (session.status == SessionStatus.inactive || session.routineId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No active session.')),
      );
    }

    final routine = routines.firstWhere((r) => r.id == session.routineId);
    final currentAlarm = routine.alarms[session.activeAlarmIndex];
    final remainingSeconds = (currentAlarm.durationSeconds - session.elapsedSeconds).clamp(0, currentAlarm.durationSeconds);
    final progress = session.elapsedSeconds / currentAlarm.durationSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              routine.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${session.activeAlarmIndex + 1} of ${routine.alarms.length} tasks',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          if (session.status == SessionStatus.ringing)
            const _RingingBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CURRENT TASK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 2,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 48),
                _TimerDisplay(
                  seconds: remainingSeconds,
                  progress: progress,
                  isRinging: session.status == SessionStatus.ringing,
                ),
                const SizedBox(height: 64),
                _SessionControls(status: session.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingingBackground extends StatefulWidget {
  const _RingingBackground();

  @override
  State<_RingingBackground> createState() => _RingingBackgroundState();
}

class _RingingBackgroundState extends State<_RingingBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.error.withValues(alpha: 0.1 * _controller.value),
                Theme.of(context).colorScheme.error.withValues(alpha: 0.2 * _controller.value),
                Colors.transparent,
              ],
              radius: 1.5,
            ),
          ),
        );
      },
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int seconds;
  final double progress;
  final bool isRinging;

  const _TimerDisplay({
    required this.seconds,
    required this.progress,
    required this.isRinging,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds / 60).floor();
    final remainingSecs = seconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            value: 1.0 - progress,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: isRinging ? theme.colorScheme.error : theme.colorScheme.primary,
          ),
        ),
        if (isRinging)
          _PulsingTimer(timeStr: timeStr)
        else
          Text(
            timeStr,
            style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 72,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
          ),
      ],
    );
  }
}

class _PulsingTimer extends StatefulWidget {
  final String timeStr;
  const _PulsingTimer({required this.timeStr});

  @override
  State<_PulsingTimer> createState() => _PulsingTimerState();
}

class _PulsingTimerState extends State<_PulsingTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.timeStr,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 72,
              color: Theme.of(context).colorScheme.error,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}

class _SessionControls extends ConsumerWidget {
  final SessionStatus status;

  const _SessionControls({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activeSessionControllerProvider.notifier);
    final theme = Theme.of(context);

    if (status == SessionStatus.ringing) {
      final session = ref.watch(activeSessionControllerProvider);
      final routines = ref.watch(routineListProvider).value ?? [];
      final routine = routines.firstWhere((r) => r.id == session.routineId);
      final isLastAlarm = session.activeAlarmIndex == routine.alarms.length - 1;
      
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () async {
                await controller.nextAlarm();
                if (context.mounted && isLastAlarm) {
                  AppTheme.showPremiumSnackBar(
                    context,
                    "Routine '${routine.name}' finished!",
                  );
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isLastAlarm ? Icons.check_circle : Icons.skip_next_rounded),
                  const SizedBox(width: 12),
                  Text(
                    isLastAlarm ? 'FINISH ROUTINE' : 'NEXT TASK',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _confirmStop(context, controller),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('STOP ROUTINE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              onPressed: () => status == SessionStatus.running 
                ? controller.pauseSession() 
                : controller.resumeSession(),
              icon: status == SessionStatus.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              isPrimary: true,
            ),
          ],
        ),
        const SizedBox(height: 48),
        TextButton.icon(
          onPressed: () => _confirmStop(context, controller),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('STOP ROUTINE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _confirmStop(BuildContext context, ActiveSessionController controller) {
    HapticFeedback.vibrate();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StopConfirmationSheet(onConfirm: () {
        controller.stopSession();
        context.go('/');
      }),
    );
  }
}

class _StopConfirmationSheet extends StatelessWidget {
  final VoidCallback onConfirm;

  const _StopConfirmationSheet({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Stop Routine?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This will end your current session. All progress will be lost.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.vibrate();
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size.fromHeight(64),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('STOP ROUTINE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      minimumSize: const Size.fromHeight(64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                    child: const Text(
                      'NOT NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool isPrimary;

  const _ControlButton({
    required this.onPressed,
    required this.icon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : null,
      ),
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon, size: 40),
        padding: const EdgeInsets.all(24),
        style: IconButton.styleFrom(
          backgroundColor: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
