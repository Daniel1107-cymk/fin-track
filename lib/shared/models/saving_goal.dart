import 'package:isar/isar.dart';

part 'saving_goal.g.dart';

@collection
class SavingGoal {
  Id id = Isar.autoIncrement;

  late String name;

  double targetAmount = 0.0;

  double savedAmount = 0.0;

  DateTime? deadline;

  late String iconEmoji;

  DateTime createdAt = DateTime.now();
}
