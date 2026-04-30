import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/category.dart';
import '../../shared/models/wallet.dart';
import '../../shared/models/budget.dart';
import '../../shared/models/saving_goal.dart';

class DatabaseService {
  static Isar? _instance;

  static Future<Isar> get instance async {
    if (_instance != null) return _instance!;
    _instance = await _init();
    return _instance!;
  }

  static Future<Isar> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        TransactionSchema,
        CategorySchema,
        WalletSchema,
        BudgetSchema,
        SavingGoalSchema,
      ],
      directory: dir.path,
    );
    return isar;
  }

  static Future<void> seedData() async {
    final isar = await instance;

    final existingWallets = await isar.wallets.where().findAll();
    if (existingWallets.isEmpty) {
      final wallets = [
        Wallet()
          ..name = 'Cash'
          ..iconName = 'wallet'
          ..colorHex = '#4ECDC4'
          ..balance = 500000
          ..currency = 'IDR'
          ..isDefault = true,
        Wallet()
          ..name = 'Bank'
          ..iconName = 'bank'
          ..colorHex = '#7C6FF7'
          ..balance = 2500000
          ..currency = 'IDR',
        Wallet()
          ..name = 'E-Wallet'
          ..iconName = 'mobile'
          ..colorHex = '#FFD93D'
          ..balance = 750000
          ..currency = 'IDR',
      ];
      await isar.writeTxn(() async {
        await isar.wallets.putAll(wallets);
      });
    }

    final existingCategories = await isar.categorys.where().findAll();
    if (existingCategories.isEmpty) {
      final categories = [
        Category()
          ..name = 'Salary'
          ..iconName = 'moneys'
          ..colorHex = '#4ECDC4'
          ..type = CategoryType.income
          ..isDefault = true,
        Category()
          ..name = 'Freelance'
          ..iconName = 'briefcase'
          ..colorHex = '#7C6FF7'
          ..type = CategoryType.income
          ..isDefault = true,
        Category()
          ..name = 'Investment'
          ..iconName = 'chart'
          ..colorHex = '#FFD93D'
          ..type = CategoryType.income
          ..isDefault = true,
        Category()
          ..name = 'Other Income'
          ..iconName = 'add-circle'
          ..colorHex = '#8A8AA0'
          ..type = CategoryType.income
          ..isDefault = true,
        Category()
          ..name = 'Food'
          ..iconName = 'coffee'
          ..colorHex = '#FF6B6B'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Transport'
          ..iconName = 'car'
          ..colorHex = '#4ECDC4'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Shopping'
          ..iconName = 'bag'
          ..colorHex = '#7C6FF7'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Health'
          ..iconName = 'heart'
          ..colorHex = '#FF6B6B'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Entertainment'
          ..iconName = 'music'
          ..colorHex = '#FFD93D'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Bills'
          ..iconName = 'receipt'
          ..colorHex = '#FF6B6B'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Education'
          ..iconName = 'book'
          ..colorHex = '#4ECDC4'
          ..type = CategoryType.expense
          ..isDefault = true,
        Category()
          ..name = 'Other Expense'
          ..iconName = 'more'
          ..colorHex = '#8A8AA0'
          ..type = CategoryType.expense
          ..isDefault = true,
      ];
      await isar.writeTxn(() async {
        await isar.categorys.putAll(categories);
      });
    }
  }
}
