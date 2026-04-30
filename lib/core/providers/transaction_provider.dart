import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transaction.dart';
import '../../shared/models/wallet.dart';
import 'database_provider.dart';

final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(
  () => TransactionsNotifier(),
);

class TransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final isar = await ref.watch(databaseProvider.future);
    return await isar.transactions.where().sortByDateDesc().findAll();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);

      // Update wallet balance based on transaction type
      final wallet = await isar.wallets.get(transaction.walletId);
      if (wallet != null) {
        if (transaction.type == TransactionType.expense) {
          wallet.balance -= transaction.amount;
        } else {
          wallet.balance += transaction.amount;
        }
        await isar.wallets.put(wallet);
      }
    });
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(int id, TransactionType type, double amount, int walletId) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.transactions.delete(id);

      // Revert wallet balance on delete
      final wallet = await isar.wallets.get(walletId);
      if (wallet != null) {
        if (type == TransactionType.expense) {
          wallet.balance += amount;
        } else {
          wallet.balance -= amount;
        }
        await isar.wallets.put(wallet);
      }
    });
    ref.invalidateSelf();
  }
}
