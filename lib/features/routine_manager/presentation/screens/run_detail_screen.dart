import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/history_controller.dart';
import '../../domain/entities/routine_run.dart';

/// Run Detail Screen - Displays the metadata for a single routine execution.
/// // Fulfills INT-17
class RunDetailScreen extends ConsumerWidget {
  final String runId;

  const RunDetailScreen({super.key, required this.runId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Summary'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        data: (history) {
          final run = history.firstWhere(
            (e) => e.id == runId,
            orElse: () => throw Exception('Run not found'),
          );

          return _buildDetailContent(context, run);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, RoutineRun run) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = run.status == RunStatus.completed;
    final statusColor = isCompleted ? Colors.green : colorScheme.error;

    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(run.endTime);
    final startTimeStr = DateFormat('h:mm a').format(run.startTime);
    final endTimeStr = DateFormat('h:mm a').format(run.endTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(context, isCompleted, statusColor),
          const SizedBox(height: 32),
          Text(
            run.routineName,
            style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            dateStr,
            style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 48),
          _buildInfoRow(
            context,
            Icons.access_time_rounded,
            'Duration',
            _formatDuration(run.totalDuration),
            color: colorScheme.primary,
          ),
          const Divider(height: 48),
          _buildInfoRow(
            context,
            Icons.play_circle_outline_rounded,
            'Started At',
            startTimeStr,
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
            context,
            Icons.stop_circle_outlined,
            'Finished At',
            endTimeStr,
          ),
          const SizedBox(height: 64),
          _buildDetailFooter(context, run),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, bool isCompleted, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.stop_circle_rounded,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            isCompleted ? 'ROUTINE COMPLETED' : 'SESSION STOPPED',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (color ?? colorScheme.onSurfaceVariant).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailFooter(BuildContext context, RoutineRun run) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 16),
            const SizedBox(height: 8),
            Text(
              'Session ID: ${run.id}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
