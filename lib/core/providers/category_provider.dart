import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/category.dart';
import 'database_provider.dart';

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  () => CategoriesNotifier(),
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final isar = await ref.watch(databaseProvider.future);
    return await isar.categorys.where().findAll();
  }
}
