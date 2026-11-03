import 'dart:async';

import 'package:sameva/core/audio/sons.dart';

/// Configuration commune des tests : pas de son (aucun lecteur audio en test).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Sons.desactiveGlobalement = true;
  await testMain();
}
