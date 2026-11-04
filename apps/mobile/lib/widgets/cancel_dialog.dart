import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> confirmCancellation(BuildContext context, LoanItem item) async {
  final bloc = context.read<MyLoansBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Otkazati pozajmicu?'),
      content: Text('${item.gameTitle}. Ovo ne može da se vrati.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Otkaži pozajmicu')),
      ],
    ),
  );
  if (confirmed != true) return;
  bloc.add(LoanCancellationRequested(item.loan.id));
}
