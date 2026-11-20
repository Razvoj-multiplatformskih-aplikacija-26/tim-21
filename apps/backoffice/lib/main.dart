import 'package:api_client/api_client.dart';
import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';

void main() {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(
    BackofficeApp(
      dependencies: AppDependencies.server(
        baseUri: Uri.parse(const String.fromEnvironment('SERVER_URL', defaultValue: 'http://localhost:8080')),
        tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
      ),
    ),
  );
}
