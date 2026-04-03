import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/alarm.dart';
import '../controllers/routine_builder_controller.dart';
import '../widgets/alarm_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain_error.dart';

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
        title: Text(
          widget.initialRoutine == null ? 'Create' : 'Edit',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Set All Durations',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: routine.alarms.isEmpty
                ? null
                : () => _showBulkDurationSheet(context, controller),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: routine.alarms.isEmpty || _nameController.text.isEmpty
                  ? null
                  : () async {
                      final result = await controller.save();
                      
                      if (!context.mounted) return;

                      result.when(
                        onSuccess: (_) {
                          context.pop();
                          AppTheme.showPremiumSnackBar(
                            context,
                            'Routine saved successfully',
                          );
                        },
                        onFailure: (error) {
                          String message = 'Failed to save routine';
                          if (error == DomainError.invalidRoutine) {
                            message = 'Routine must have at least one task';
                          } else if (error == DomainError.storageFailure) {
                            message = 'Storage error: Failed to save to disk';
                          }
                          
                          AppTheme.showPremiumSnackBar(
                            context,
                            message,
                            isError: true,
                          );
                        },
                      );
                    },
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                backgroundColor: routine.alarms.isEmpty || _nameController.text.isEmpty
                    ? null
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TextField(
              controller: _nameController,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              decoration: const InputDecoration(
                hintText: 'Routine Name',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (val) => controller.updateName(val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Session Tasks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${routine.alarms.length} items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                        onTap: () => _showAlarmDurationSheet(context, controller, existingAlarm: alarm),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAlarmDurationSheet(context, controller),
        label: const Text('Add Task'),
        icon: const Icon(Icons.add_task_rounded),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyAlarmsState(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Start by adding your first task'),
          ],
        ),
      ),
    );
  }

  Future<void> _showBulkDurationSheet(
    BuildContext context,
    RoutineBuilder controller,
  ) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DurationPickerSheet(
        title: 'Set All Durations',
        confirmLabel: 'Apply to All',
      ),
    );

    if (result != null && result > 0) {
      controller.bulkUpdateAlarmDurations(result);
    }
  }

  Future<void> _showAlarmDurationSheet(
    BuildContext context,
    RoutineBuilder controller, {
    Alarm? existingAlarm,
  }) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DurationPickerSheet(
        title: existingAlarm == null ? 'Add Task' : 'Edit Duration',
        initialSeconds: existingAlarm?.durationSeconds ?? 60,
        confirmLabel: existingAlarm == null ? 'Add' : 'Save',
      ),
    );

    if (result != null && result > 0) {
      if (existingAlarm == null) {
        controller.addAlarm(result);
      } else {
        controller.updateAlarmDuration(existingAlarm.id, result);
      }
    }
  }
}

class _DurationPickerSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final int initialSeconds;

  const _DurationPickerSheet({
    required this.title,
    required this.confirmLabel,
    this.initialSeconds = 60,
  });

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late int selectedMinutes;
  late int selectedSeconds;
  
  late FixedExtentScrollController minController;
  late FixedExtentScrollController secController;

  @override
  void initState() {
    super.initState();
    selectedMinutes = widget.initialSeconds ~/ 60;
    selectedSeconds = widget.initialSeconds % 60;
    minController = FixedExtentScrollController(initialItem: selectedMinutes);
    secController = FixedExtentScrollController(initialItem: selectedSeconds);
  }

  @override
  void dispose() {
    minController.dispose();
    secController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Selection Highlight
                    Center(
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWheel(
                          controller: minController,
                          label: 'min',
                          itemCount: 60,
                          onChanged: (val) {
                            setState(() => selectedMinutes = val);
                            HapticFeedback.selectionClick();
                          },
                        ),
                        const SizedBox(width: 40),
                        _buildWheel(
                          controller: secController,
                          label: 'sec',
                          itemCount: 60,
                          onChanged: (val) {
                            setState(() => selectedSeconds = val);
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        minimumSize: const Size.fromHeight(64),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colorScheme.outlineVariant),
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (selectedMinutes == 0 && selectedSeconds == 0)
                          ? null
                          : () => Navigator.pop(context, (selectedMinutes * 60) + selectedSeconds),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(widget.confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required String label,
    required int itemCount,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 48,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= itemCount) return null;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
