import 'package:blocs/blocs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuardedCallbackAction<T extends Intent> extends CallbackAction<T> {
  GuardedCallbackAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}

class ApproveSelectedIntent extends Intent {
  const ApproveSelectedIntent();
}

class RejectSelectedIntent extends Intent {
  const RejectSelectedIntent();
}

Map<ShortcutActivator, Intent> loanBoardShortcuts() => {
  const SingleActivator(LogicalKeyboardKey.keyO): const ApproveSelectedIntent(),
  const SingleActivator(LogicalKeyboardKey.keyR): const RejectSelectedIntent(),
};

class LoanBoardShortcuts extends StatelessWidget {
  const LoanBoardShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LoanBoardBloc>();

    LoanBoardItem? idleSelected() => switch (bloc.state) {
      LoanBoardLoaded(:final selected, :final isBusy) when !isBusy => selected,
      _ => null,
    };

    return Shortcuts(
      shortcuts: loanBoardShortcuts(),
      child: Actions(
        actions: {
          ApproveSelectedIntent: GuardedCallbackAction<ApproveSelectedIntent>(
            enabled: () => idleSelected()?.canApprove ?? false,
            onInvoke: (_) {
              if (idleSelected() case final item?) bloc.add(LoanApprovalRequested(item.loan.id));
              return null;
            },
          ),
          RejectSelectedIntent: GuardedCallbackAction<RejectSelectedIntent>(
            enabled: () => idleSelected()?.canReject ?? false,
            onInvoke: (_) {
              if (idleSelected() case final item?) bloc.add(LoanRejectionRequested(item.loan.id));
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
