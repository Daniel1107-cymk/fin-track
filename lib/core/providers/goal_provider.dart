import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/saving_goal.dart';
import 'database_provider.dart';

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<SavingGoal>>(
  () => GoalsNotifier(),
);

class GoalsNotifier extends AsyncNotifier<List<SavingGoal>> {
  @override
  Future<List<SavingGoal>> build() async {
    final isar = await ref.watch(databaseProvider.future);
    return await isar.savingGoals.where().findAll();
  }

  Future<void> addGoal(SavingGoal goal) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.savingGoals.put(goal);
    });
    ref.invalidateSelf();
  }

  Future<void> addFunds(int goalId, double amount) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      final goal = await isar.savingGoals.get(goalId);
      if (goal != null) {
        goal.savedAmount += amount;
        await isar.savingGoals.put(goal);
      }
    });
    ref.invalidateSelf();
  }
}
