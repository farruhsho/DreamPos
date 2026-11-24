import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/money.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  // Load currency before first frame so amounts never flash in wrong format.
  final settings = await db.select(db.settings).get();
  Money.currency = CurrencyConfig.fromSettings({for (final s in settings) s.key: s.value});
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const DreamPosApp(),
  ));
}
