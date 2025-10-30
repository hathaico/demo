import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appbannon/services/firebase_product_service.dart';
import 'package:appbannon/firebase_options.dart';

// Small Flutter entrypoint that runs the one-time migration to add `name_lower`
// to existing product documents.
//
// By default this runner performs a dry-run and only reports how many
// documents would be updated. To actually apply changes, run with a
// dart-define flag:
//
// flutter run -t lib/tools/run_add_name_lower_migration.dart --dart-define=EXECUTE=true

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final execute =
      const String.fromEnvironment('EXECUTE', defaultValue: 'false') == 'true';

  print('Starting product migration: add name_lower to products');
  if (execute) {
    print('EXECUTE=true: Migration will write changes to Firestore.');
  } else {
    print(
      'Dry-run (no writes). To execute, rerun with --dart-define=EXECUTE=true',
    );
  }

  final res = await FirebaseProductService.migrateAddNameLower(
    batchSize: 200,
    dryRun: !execute,
  );
  print(
    'Migration result: updated=${res['updated']}, skipped=${res['skipped']}, errors=${res['errors']}',
  );

  // Exit the process explicitly.
  exit(0);
}
