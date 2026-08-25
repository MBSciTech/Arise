// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$MealsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MealsTable get meals => attachedDatabase.meals;
  MealsDaoManager get managers => MealsDaoManager(this);
}

class MealsDaoManager {
  final _$MealsDaoMixin _db;
  MealsDaoManager(this._db);
  $$MealsTableTableManager get meals =>
      $$MealsTableTableManager(_db.attachedDatabase, _db.meals);
}

mixin _$WorkoutsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $ExerciseSetsTable get exerciseSets => attachedDatabase.exerciseSets;
  WorkoutsDaoManager get managers => WorkoutsDaoManager(this);
}

class WorkoutsDaoManager {
  final _$WorkoutsDaoMixin _db;
  WorkoutsDaoManager(this._db);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$ExerciseSetsTableTableManager get exerciseSets =>
      $$ExerciseSetsTableTableManager(_db.attachedDatabase, _db.exerciseSets);
}
