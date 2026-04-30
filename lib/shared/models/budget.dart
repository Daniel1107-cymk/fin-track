import 'package:isar/isar.dart';

part 'budget.g.dart';

@collection
class Budget {
  Id id = Isar.autoIncrement;

  int categoryId = 0;

  double limitAmount = 0.0;

  double spentAmount = 0.0;

  int month = 0;

  int year = 0;
}
