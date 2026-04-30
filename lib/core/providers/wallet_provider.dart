import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/wallet.dart';
import 'database_provider.dart';

final walletsProvider = AsyncNotifierProvider<WalletsNotifier, List<Wallet>>(
  () => WalletsNotifier(),
);

class WalletsNotifier extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() async {
    final isar = await ref.watch(databaseProvider.future);
    return await isar.wallets.where().findAll();
  }

  Future<void> addWallet(Wallet wallet) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.wallets.put(wallet);
    });
    ref.invalidateSelf();
  }

  Future<void> updateBalance(int walletId, double newBalance) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      final wallet = await isar.wallets.get(walletId);
      if (wallet != null) {
        wallet.balance = newBalance;
        await isar.wallets.put(wallet);
      }
    });
    ref.invalidateSelf();
  }

  Future<void> updateWallet(Wallet wallet) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.wallets.put(wallet);
    });
    ref.invalidateSelf();
  }

  Future<void> setDefaultWallet(int walletId) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      final allWallets = await isar.wallets.where().findAll();
      for (final w in allWallets) {
        if (w.isDefault) {
          w.isDefault = false;
          await isar.wallets.put(w);
        }
      }
      final wallet = await isar.wallets.get(walletId);
      if (wallet != null) {
        wallet.isDefault = true;
        await isar.wallets.put(wallet);
      }
    });
    ref.invalidateSelf();
  }

  Future<void> deleteWallet(int walletId) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.wallets.delete(walletId);
    });
    ref.invalidateSelf();
  }
}
