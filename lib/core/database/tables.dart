import 'package:drift/drift.dart';

@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get age => integer().nullable()();
  RealColumn get weight => real().nullable()(); // kg
  RealColumn get height => real().nullable()(); // cm
  TextColumn get goals => text().nullable()();
  TextColumn get activityLevel => text().nullable()();
}

@DataClassName('Meal')
class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fats => real()();
  RealColumn get calories => real()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get category => text().withDefault(const Constant('Miscellaneous'))();
}

@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  IntColumn get duration => integer()(); // seconds
  RealColumn get totalCalories => real().nullable()();
}

@DataClassName('ExerciseSet')
class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  TextColumn get exerciseName => text()();
  IntColumn get sets => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real()(); // kg
  IntColumn get duration => integer().nullable()(); // seconds
}

@DataClassName('SupervisedSession')
class SupervisedSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get exerciseType => text()();
  IntColumn get repsCompleted => integer()();
  IntColumn get duration => integer()(); // seconds
  RealColumn get estimatedCalories => real().nullable()();
}

@DataClassName('ChatMessage')
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get role => text()(); // 'user' or 'ai'
  TextColumn get content => text()();
}

@DataClassName('DailyHealthMetric')
class DailyHealthMetrics extends Table {
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer().nullable()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get sleepMinutes => integer().nullable()();
  RealColumn get caloriesBurned => real().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}
