import 'package:isar/isar.dart';

part 'wallet.g.dart';

@collection
class Wallet {
  Id id = Isar.autoIncrement;

  late String name;

  late String iconName;

  late String colorHex;

  double balance = 0.0;

  late String currency;

  bool isDefault = false;

  DateTime createdAt = DateTime.now();
}
