import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/active_session_controller.dart';
import '../controllers/routine_list_controller.dart';
import '../../../../core/di/service_providers.dart';
import '../../domain/usecases/verify_permissions.dart';
import '../../domain/entities/active_session.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain_error.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(width: 8),
        ],
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
                    _handleRoutineStart(context, ref, routine);
                  }
                },
                onDelete: () async {
                  final result = await ref.read(routineListProvider.notifier).deleteRoutine(routine.id);
                  if (!context.mounted) return;
                  
                  result.when(
                    onSuccess: (_) {
                      AppTheme.showPremiumSnackBar(
                        context,
                        'Routine deleted successfully',
                      );
                    },
                    onFailure: (error) {
                      String message = 'Failed to delete routine';
                      if (error == DomainError.activeSessionExists) {
                        message = 'Cannot delete a routine while it is running';
                      }
                      
                      AppTheme.showPremiumSnackBar(
                        context,
                        message,
                        isError: true,
                      );
                    },
                  );
                },
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

  Future<void> _handleRoutineStart(BuildContext context, WidgetRef ref, dynamic routine) async {
    final permissionResult = await ref.read(verifyPermissionsProvider.future);

    if (permissionResult.isSuccess) {
      try {
        await ref.read(activeSessionControllerProvider.notifier).startRoutine(routine);
        if (context.mounted) {
          context.push('/session');
        }
      } on StateError catch (error) {
        if (context.mounted) {
          AppTheme.showPremiumSnackBar(context, error.message, isError: true);
        }
      }
    } else {
      if (context.mounted) {
        _showPermissionDeniedDialog(context, ref);
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'To provide accurate alarms, the app requires notification and background execution permissions. Please enable them in system settings.',
          textAlign: TextAlign.center,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationServiceProvider).requestPermissions();
            },
            child: const Text('GRANT ACCESS'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No routines yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first routine to start optimizing your productivity.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassDecoration(context),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCurrent
                            ? [colorScheme.primary, colorScheme.secondary]
                            : [colorScheme.primaryContainer, colorScheme.primaryContainer.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isCurrent 
                        ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                        : null,
                    ),
                    child: Icon(
                      isCurrent ? Icons.timer : Icons.play_arrow_rounded,
                      size: 32,
                      color: isOtherActive
                          ? colorScheme.onSurfaceVariant
                          : (isCurrent
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Opacity(
                  opacity: isOtherActive ? 0.5 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Untitled Routine' : name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$alarmCount alarms',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!isCurrent)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: colorScheme.error,
                    onPressed: () => _confirmDelete(context, name, onDelete),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String routineName, VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Delete Routine?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "Are you sure you want to delete '${routineName.isEmpty ? 'Untitled Routine' : routineName}'? This action cannot be undone.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
                AppTheme.showPremiumSnackBar(context, 'Routine deleted');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('DELETE PERMANENTLY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => context.push('/session'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_rounded,
                    color: colorScheme.onSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ongoing Session',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                            ),
                      ),
                      const Text(
                        'Tap to return to routine',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.status.name.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
