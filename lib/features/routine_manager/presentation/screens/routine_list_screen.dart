import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/active_session_controller.dart';
import '../controllers/routine_list_controller.dart';
import '../../domain/entities/active_session.dart';

/// Routine List Screen - Home screen showing all saved routines.
/// // Fulfills INT-01, INT-03, INT-09
class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);
    final activeSession = ref.watch(activeSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routines'),
        centerTitle: true,
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              final isCurrent = activeSession.routineId == routine.id;
              final isOtherActive = activeSession.status != SessionStatus.inactive && !isCurrent;

              return _RoutineCard(
                name: routine.name,
                alarmCount: routine.alarms.length,
                isCurrent: isCurrent,
                isOtherActive: isOtherActive,
                onTap: () => context.push('/builder', extra: routine),
                onPlay: () {
                  if (isCurrent) {
                    context.push('/session');
                  } else {
                    () async {
                      try {
                        await ref
                            .read(activeSessionControllerProvider.notifier)
                            .startRoutine(routine);
                        if (context.mounted) {
                          context.push('/session');
                        }
                      } on StateError catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
                    }();
                  }
                },
                onDelete: () => ref.read(routineListProvider.notifier).deleteRoutine(routine.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: activeSession.status != SessionStatus.inactive
          ? _ActiveSessionBanner(session: activeSession)
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/builder'),
        label: const Text('New Routine'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'No routines yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Create your first routine to get started!'),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final String name;
  final int alarmCount;
  final bool isCurrent;
  final bool isOtherActive;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.name,
    required this.alarmCount,
    required this.isCurrent,
    required this.isOtherActive,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (isCurrent || isOtherActive) ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: isOtherActive ? null : onPlay,
                child: Opacity(
                  opacity: isOtherActive ? 0.5 : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCurrent ? Icons.timer : Icons.play_arrow_rounded,
                      color: isOtherActive
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : (isCurrent
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Opacity(
                  opacity: (isCurrent || isOtherActive) ? 0.6 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Untitled Routine' : name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$alarmCount alarms',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: isCurrent ? null : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Routine?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            onDelete();
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final ActiveSession session;

  const _ActiveSessionBanner({required this.session});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => context.push('/session'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ongoing Routine Session',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                session.status.name.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
