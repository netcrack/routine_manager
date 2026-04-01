import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/active_session_controller.dart';
import '../controllers/routine_list_controller.dart';
import '../../domain/entities/active_session.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef title) {
    final session = title.watch(activeSessionControllerProvider);
    final routines = title.watch(routineListProvider).value ?? [];
    
    // Inactive or missing data safety
    if (session.status == SessionStatus.inactive || session.routineId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No active session.')),
      );
    }

    final routine = routines.firstWhere((r) => r.id == session.routineId);
    final currentAlarm = routine.alarms[session.activeAlarmIndex];
    final remainingSeconds = currentAlarm.durationSeconds - session.elapsedSeconds;

    return Scaffold(
      backgroundColor: session.status == SessionStatus.ringing 
          ? Theme.of(context).colorScheme.errorContainer 
          : null,
      appBar: AppBar(
        title: Text(routine.name),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentAlarm.id.isEmpty ? 'Alarm ${session.activeAlarmIndex + 1}' : 'Task ${session.activeAlarmIndex + 1}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _TimerDisplay(
              seconds: remainingSeconds,
              isRinging: session.status == SessionStatus.ringing,
            ),
            const SizedBox(height: 48),
            _SessionControls(status: session.status),
          ],
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int seconds;
  final bool isRinging;

  const _TimerDisplay({required this.seconds, required this.isRinging});

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds / 60).floor();
    final remainingSecs = seconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: isRinging ? 1.2 : 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Text(
            timeStr,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isRinging ? Theme.of(context).colorScheme.error : null,
                  fontSize: 80,
                ),
          ),
        );
      },
      onEnd: () {
        // Simple way to pulse - actually would need a repeating animation but this works for basic signal
      },
    );
  }
}

class _SessionControls extends ConsumerWidget {
  final SessionStatus status;

  const _SessionControls({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(activeSessionControllerProvider.notifier);

    if (status == SessionStatus.completed) {
      return ElevatedButton.icon(
        onPressed: () {
          controller.stopSession();
          context.go('/');
        },
        icon: const Icon(Icons.check),
        label: const Text('Finish Routine'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    if (status == SessionStatus.ringing) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => controller.nextAlarm(),
            icon: const Icon(Icons.skip_next),
            label: const Text('Next Alarm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _confirmStop(context, controller),
            child: const Text('Stop Routine'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (status == SessionStatus.running)
              IconButton.filled(
                onPressed: () => controller.pauseSession(),
                icon: const Icon(Icons.pause, size: 32),
                padding: const EdgeInsets.all(16),
              )
            else
              IconButton.filled(
                onPressed: () => controller.resumeSession(),
                icon: const Icon(Icons.play_arrow, size: 32),
                padding: const EdgeInsets.all(16),
              ),
          ],
        ),
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: () => _confirmStop(context, controller),
          icon: const Icon(Icons.stop),
          label: const Text('Stop Routine'),
        ),
      ],
    );
  }

  void _confirmStop(BuildContext context, ActiveSessionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Routine?'),
        content: const Text('This will end your current session. All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.stopSession();
              Navigator.pop(context);
              GoRouter.of(context).go('/');
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
