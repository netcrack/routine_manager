import 'package:flutter/material.dart';
import '../../domain/entities/alarm.dart';

/// Alarm Item Widget - Individual alarm display in the builder list.
/// // Fulfills INT-02, INT-04
class AlarmItem extends StatelessWidget {
  final Alarm alarm;
  final VoidCallback onRemove;
  final int index;

  const AlarmItem({
    super.key,
    required this.alarm,
    required this.onRemove,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = alarm.durationSeconds ~/ 60;
    final seconds = alarm.durationSeconds % 60;
    final durationText = '${minutes}m ${seconds}s';

    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Alarm ${index + 1}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Duration: $durationText',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.drag_indicator_rounded),
      ),
    );
  }
}
