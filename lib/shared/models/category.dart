import 'package:isar/isar.dart';

part 'category.g.dart';

@collection
class Category {
  Id id = Isar.autoIncrement;

  late String name;

  late String iconName;

  late String colorHex;

  @enumerated
  late CategoryType type;

  bool isDefault = false;
}

enum CategoryType { income, expense }
