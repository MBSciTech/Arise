import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Meals])
class MealsDao extends DatabaseAccessor<AppDatabase> with _$MealsDaoMixin {
  MealsDao(AppDatabase db) : super(db);

  Stream<List<Meal>> watchMealsForDate(DateTime startOfDay, DateTime endOfDay) {
    return (select(meals)
          ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<Meal>> getRecentDistinctMeals() async {
    final recentMeals = await (select(meals)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
          ..limit(50))
        .get();
    
    final uniqueNames = <String>{};
    final distinctMeals = <Meal>[];
    
    for (var meal in recentMeals) {
      if (uniqueNames.add(meal.name.toLowerCase())) {
        distinctMeals.add(meal);
      }
    }
    
    return distinctMeals;
  }

  Future<int> insertMeal(MealsCompanion meal) => into(meals).insert(meal);
  Future<bool> updateMeal(MealsCompanion meal) => update(meals).replace(meal);
  Future<int> deleteMeal(Meal meal) => delete(meals).delete(meal);
}

@DriftAccessor(tables: [Workouts, ExerciseSets])
class WorkoutsDao extends DatabaseAccessor<AppDatabase> with _$WorkoutsDaoMixin {
  WorkoutsDao(AppDatabase db) : super(db);

  Stream<List<Workout>> watchAllWorkouts() {
    return (select(workouts)
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<ExerciseSet>> getSetsForWorkout(int workoutId) {
    return (select(exerciseSets)..where((t) => t.workoutId.equals(workoutId))).get();
  }

  Future<int> insertWorkout(WorkoutsCompanion workout) => into(workouts).insert(workout);
  Future<int> insertExerciseSet(ExerciseSetsCompanion set) => into(exerciseSets).insert(set);
}
