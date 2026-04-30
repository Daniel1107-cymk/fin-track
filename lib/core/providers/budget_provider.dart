import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/budget.dart';
import 'database_provider.dart';

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(
  () => BudgetsNotifier(),
);

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final isar = await ref.watch(databaseProvider.future);
    final now = DateTime.now();
    return await isar.budgets
        .filter()
        .monthEqualTo(now.month)
        .yearEqualTo(now.year)
        .findAll();
  }

  Future<void> addBudget(int categoryId, double limitAmount) async {
    final isar = await ref.read(databaseProvider.future);
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final budget = Budget()
        ..categoryId = categoryId
        ..limitAmount = limitAmount
        ..spentAmount = 0
        ..month = now.month
        ..year = now.year;
      await isar.budgets.put(budget);
    });
    ref.invalidateSelf();
  }

  Future<void> updateSpent(int budgetId, double amount) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      final budget = await isar.budgets.get(budgetId);
      if (budget != null) {
        budget.spentAmount += amount;
        await isar.budgets.put(budget);
      }
    });
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(int budgetId) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.budgets.delete(budgetId);
    });
    ref.invalidateSelf();
  }
}
