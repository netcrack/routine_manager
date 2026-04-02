import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/alarm.dart';
import '../controllers/routine_builder_controller.dart';
import '../widgets/alarm_item.dart';

/// Routine Builder Screen - Screen for creating or editing a routine.
/// // Fulfills INT-01, INT-02, INT-04, INT-10
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  final Routine? initialRoutine;

  const RoutineBuilderScreen({super.key, this.initialRoutine});

  @override
  ConsumerState<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final routine = ref.read(routineBuilderProvider(initialRoutine: widget.initialRoutine));
    _nameController = TextEditingController(text: routine.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = ref.watch(routineBuilderProvider(initialRoutine: widget.initialRoutine));
    final controller = ref.read(routineBuilderProvider(initialRoutine: widget.initialRoutine).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRoutine == null ? 'Create Routine' : 'Edit Routine'),
        actions: [
          IconButton(
            tooltip: 'Set All Durations',
            icon: const Icon(Icons.timer_outlined),
            onPressed: routine.alarms.isEmpty
                ? null
                : () => _showBulkDurationPicker(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: routine.alarms.isEmpty || _nameController.text.isEmpty
                ? null
                : () async {
                    try {
                      await controller.save();
                      if (context.mounted) context.pop();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save routine: $e')),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Morning Yoga',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => controller.updateName(val),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alarms',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${routine.alarms.length} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: routine.alarms.isEmpty
                ? _buildEmptyAlarmsState(context)
                : ReorderableListView.builder(
                    itemCount: routine.alarms.length,
                    onReorder: controller.reorderAlarms,
                    itemBuilder: (context, index) {
                      final alarm = routine.alarms[index];
                      return AlarmItem(
                        key: ValueKey(alarm.id),
                        alarm: alarm,
                        index: index,
                        onRemove: () => controller.removeAlarm(alarm.id),
                        onTap: () => _showAlarmDurationPicker(context, controller, existingAlarm: alarm),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAlarmDurationPicker(context, controller),
        label: const Text('Add Alarm'),
        icon: const Icon(Icons.add_alarm_rounded),
      ),
    );
  }

  Widget _buildEmptyAlarmsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_alarm_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          const SizedBox(height: 16),
          const Text('At least one alarm is required.'),
        ],
      ),
    );
  }

  Future<void> _showBulkDurationPicker(
    BuildContext context,
    RoutineBuilder controller,
  ) async {
    int minutes = 1;
    int seconds = 0;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set All Alarm Durations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Apply this duration to all alarms:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPicker(
                  label: 'Min',
                  value: minutes,
                  onChanged: (val) => minutes = val,
                ),
                const SizedBox(width: 24),
                _buildPicker(
                  label: 'Sec',
                  value: seconds,
                  onChanged: (val) => seconds = val,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final totalSeconds = (minutes * 60) + seconds;
              if (totalSeconds > 0) {
                Navigator.pop(context, totalSeconds);
              }
            },
            child: const Text('Apply to All'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      controller.bulkUpdateAlarmDurations(result);
    }
  }

  Future<void> _showAlarmDurationPicker(
    BuildContext context, 
    RoutineBuilder controller, {
    Alarm? existingAlarm,
  }) async {
    int minutes = existingAlarm != null ? existingAlarm.durationSeconds ~/ 60 : 1;
    int seconds = existingAlarm != null ? existingAlarm.durationSeconds % 60 : 0;
 
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingAlarm == null ? 'Add New Alarm' : 'Edit Alarm Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Duration:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPicker(
                  label: 'Min',
                  value: minutes,
                  onChanged: (val) => minutes = val,
                ),
                const SizedBox(width: 24),
                _buildPicker(
                  label: 'Sec',
                  value: seconds,
                  onChanged: (val) => seconds = val,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final totalSeconds = (minutes * 60) + seconds;
              if (totalSeconds > 0) {
                if (existingAlarm == null) {
                  controller.addAlarm(totalSeconds);
                } else {
                  controller.updateAlarmDuration(existingAlarm.id, totalSeconds);
                }
                Navigator.pop(context);
              }
            },
            child: Text(existingAlarm == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: value > 0
                      ? () => setState(() {
                            value--;
                            onChanged(value);
                          })
                      : null,
                ),
                Text(
                  value.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: value < 59
                      ? () => setState(() {
                            value++;
                            onChanged(value);
                          })
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
