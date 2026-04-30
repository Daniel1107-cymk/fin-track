import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../database/database_service.dart';

final databaseProvider = FutureProvider<Isar>((ref) async {
  return await DatabaseService.instance;
});
