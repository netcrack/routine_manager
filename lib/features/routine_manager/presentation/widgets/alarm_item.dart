import 'package:flutter/material.dart';
import '../../domain/entities/alarm.dart';
import '../../../../core/theme/app_theme.dart';

/// Alarm Item Widget - Individual alarm display in the builder list.
/// // Fulfills INT-02, INT-04
class AlarmItem extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onRemove;
  final VoidCallback? onTap;
  final int index;

  const AlarmItem({
    super.key,
    required this.alarm,
    required this.onRemove,
    this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = alarm.durationSeconds ~/ 60;
    final seconds = alarm.durationSeconds % 60;
    final durationText = '${minutes}m ${seconds}s';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppTheme.glassDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: ValueKey(alarm.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade800],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        onDismissed: (_) => onRemove(),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                'Task ${index + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    durationText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
