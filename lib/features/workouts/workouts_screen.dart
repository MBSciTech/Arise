import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/services/pose_detector_service.dart';
import 'add_workout_screen.dart';
import 'active_workout_screen.dart';

final workoutsProvider = StreamProvider<List<Workout>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.workoutsDao.watchAllWorkouts();
});

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workoutsAsync = ref.watch(workoutsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Workouts & AI Trainer'),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Supervised Training', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AiTrainerCard(
                          title: 'Squats',
                          icon: Icons.accessibility_new,
                          onTap: () => _startSupervisedSession(context, 'Squats'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AiTrainerCard(
                          title: 'Push-ups',
                          icon: Icons.fitness_center,
                          onTap: () => _startSupervisedSession(context, 'Push-ups'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          workoutsAsync.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text('No workouts logged yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ).animate().fade().slideY(begin: 0.2),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final workout = workouts[index];
                    return _WorkoutCard(workout: workout).animate().fade(delay: (index * 50).ms).slideX(begin: 0.2);
                  },
                  childCount: workouts.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.fitness_center, color: theme.colorScheme.onTertiaryContainer),
        ),
        title: Text(workout.type, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(dateFormat.format(workout.date), style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to workout details / sets later
        },
      ),
    );
  }
}

void _startSupervisedSession(BuildContext context, String type) async {
  final exercise = type == 'Squats' ? ExerciseType.squats : ExerciseType.pushups;
  
  final result = await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ActiveWorkoutScreen(exercise: exercise, exerciseName: type),
    ),
  );
  
  if (result != null && result is int && result > 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Great job! You completed $result reps of $type!')),
    );
  }
}

class _AiTrainerCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AiTrainerCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
