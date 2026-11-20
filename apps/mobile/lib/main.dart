import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';
import 'server_address.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(
    BoardGameApp(
      dependencies: AppDependencies.server(baseUri: serverAddress(), tokens: const SecureTokenStore()),
    ),
  );
}
