import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart';
import '../../core/theme/theme.dart';
import 'add_meal_screen.dart';

final todaysMealsProvider = StreamProvider<List<Meal>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return db.mealsDao.watchMealsForDate(startOfDay, endOfDay);
});

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mealsAsync = ref.watch(todaysMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () {}),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DateSelectorStrip().animate().fade().slideY(begin: 0.1),
          ),
          SliverToBoxAdapter(
            child: mealsAsync.when(
              data: (meals) => _DietDashboard(meals: meals),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Meal',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Edit plan',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ).animate().fade().slideY(begin: 0.1),
            ),
          ),
          mealsAsync.when(
            data: (meals) {
              if (meals.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meal = meals[index];
                    return _MealCard(meal: meal).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1);
                  },
                  childCount: meals.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
        ],
      ),
    );
  }
}

class _DateSelectorStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: today.weekday - 1 - index));
          final isToday = date.day == today.day;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.E().format(date).substring(0, 3),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? theme.colorScheme.primary : Colors.transparent,
                    border: isToday ? null : Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isToday ? Colors.black : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DietDashboard extends StatelessWidget {
  final List<Meal> meals;

  const _DietDashboard({required this.meals});

  @override
  Widget build(BuildContext context) {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (var meal in meals) {
      totalCalories += meal.calories.toInt();
      totalProtein += meal.protein.toInt();
      totalCarbs += meal.carbs.toInt();
      totalFat += meal.fats.toInt();
    }

    const goalCalories = 1500;
    const goalProtein = 158;
    const goalCarbs = 174;
    const goalFat = 83;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 5,
            child: _MainCalorieRing(
              consumed: totalCalories,
              goal: goalCalories,
            ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MacroIndicator(label: 'Carbs', consumed: totalCarbs, goal: goalCarbs, color: AppTheme.primary),
                const SizedBox(height: 16),
                _MacroIndicator(label: 'Proteins', consumed: totalProtein, goal: goalProtein, color: AppTheme.primary),
                const SizedBox(height: 16),
                _MacroIndicator(label: 'Fats', consumed: totalFat, goal: goalFat, color: AppTheme.accentPurple),
              ],
            ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
          ),
        ],
      ),
    );
  }
}

class _MainCalorieRing extends StatelessWidget {
  final int consumed;
  final int goal;

  const _MainCalorieRing({required this.consumed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (consumed / goal).clamp(0.0, 1.0);
    
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              sectionsSpace: 4, // Gaps like the image
              centerSpaceRadius: double.infinity,
              sections: [
                PieChartSectionData(
                  value: percent * 100,
                  color: theme.colorScheme.primary,
                  showTitle: false,
                  radius: 14,
                ),
                PieChartSectionData(
                  value: (1 - percent) * 100,
                  color: theme.colorScheme.surfaceContainerHighest,
                  showTitle: false,
                  radius: 14,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Day 12', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apple, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    '$consumed',
                    style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '$goal Kcal',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroIndicator extends StatelessWidget {
  final String label;
  final int consumed;
  final int goal;
  final Color color;

  const _MacroIndicator({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (consumed / goal).clamp(0.0, 1.0);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$consumed/${goal}g', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 8,
          height: 36,
          child: RotatedBox(
            quarterTurns: 3, // Vertical bar
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealCard extends ConsumerWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  void _showOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Meal Options', style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white),
                  title: const Text('Edit Meal'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddMealScreen(mealToEdit: meal)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text('Delete Meal', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(context);
                    final db = ref.read(appDatabaseProvider);
                    await db.mealsDao.deleteMeal(meal);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final qtyStr = meal.quantity % 1 == 0 ? meal.quantity.toInt().toString() : meal.quantity.toString();
    
    return GestureDetector(
      onLongPress: () => _showOptions(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          // Subtle glowing gradient based on the image
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainer,
              theme.colorScheme.surfaceContainer.withOpacity(0.5),
              AppTheme.accentPurple.withOpacity(0.1),
              AppTheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${meal.name} (x$qtyStr)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal.category,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${meal.calories.toInt()} kcal',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                Text(
                  'P:${meal.protein.toInt()} C:${meal.carbs.toInt()} F:${meal.fats.toInt()}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
