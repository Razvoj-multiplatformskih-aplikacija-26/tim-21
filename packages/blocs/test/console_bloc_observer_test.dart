import 'package:bloc/bloc.dart';
import 'package:blocs/blocs.dart';
import 'package:test/test.dart';

sealed class _CounterEvent {
  const _CounterEvent();
}

final class _Incremented extends _CounterEvent {
  const _Incremented();
}

final class _CounterBloc extends Bloc<_CounterEvent, int> {
  _CounterBloc() : super(0) {
    on<_Incremented>((event, emit) => emit(state + 1));
  }
}

void main() {
  test('ConsoleBlocObserver logs creation, every transition and closing', () async {
    final lines = <String>[];
    Bloc.observer = ConsoleBlocObserver(lines.add);

    final bloc = _CounterBloc()..add(const _Incremented());
    await Future<void>.delayed(Duration.zero);
    await bloc.close();

    expect(lines, ['_CounterBloc · created', '_CounterBloc · _Incremented → 1', '_CounterBloc · closed']);
  });
}
