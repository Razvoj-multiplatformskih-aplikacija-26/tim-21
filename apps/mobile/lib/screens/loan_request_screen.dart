import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key, required this.id});

  final LoanId id;

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _days = TextEditingController(text: '${LoanDuration.maxDays}');

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  String? _validateDays(String? value) {
    final days = int.tryParse(value ?? '');
    if (days == null) return 'Unesite broj dana.';
    return LoanDuration.parse(days).errorOrNull?.message;
  }

  void _submit(LoanItem item) {
    if (!_formKey.currentState!.validate()) return;
    final duration = LoanDuration.parse(int.parse(_days.text)).valueOrNull!;
    context.read<MyLoansBloc>().add(LoanRequestSubmitted(game: item.loan.gameId, duration: duration));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova pozajmica')),
    body: BlocBuilder<MyLoansBloc, MyLoansState>(
      builder: (context, state) => switch (state) {
        MyLoansLoading() => const LoadingView(),
        MyLoansFailure() => FailureView(onRetry: () => context.read<MyLoansBloc>().add(const MyLoansRequested())),
        MyLoansEmpty() => const EmptyView(title: 'Pozajmica nije pronađena.'),
        MyLoansLoaded() => switch (state.items.where((item) => item.loan.id == widget.id).firstOrNull) {
          null => const EmptyView(title: 'Pozajmica nije pronađena.'),
          final item => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(item.gameTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Broj dana',
                    helperText: 'Od ${LoanDuration.minDays} do ${LoanDuration.maxDays} dana',
                  ),
                  validator: _validateDays,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => _submit(item), child: const Text('Pošalji zahtev')),
              ],
            ),
          ),
        },
      },
    ),
  );
}
