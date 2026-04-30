import 'package:isar/isar.dart';

part 'transaction.g.dart';

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  double amount = 0.0;

  @enumerated
  late TransactionType type;

  int categoryId = 0;

  int walletId = 0;

  String note = '';

  DateTime date = DateTime.now();

  String? receiptImagePath;

  bool isRecurring = false;

  DateTime createdAt = DateTime.now();
}

enum TransactionType { income, expense }
