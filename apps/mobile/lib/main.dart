import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';

void main() {
  if (kDebugMode) Bloc.observer = ConsoleBlocObserver(debugPrint);
  runApp(const BoardGameApp());
}
