import 'package:flutter/material.dart';

import '../../../shared/widgets/widgets.dart';

class ContractorsScreen extends StatelessWidget {
  const ContractorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Команда',
      body: AppEmptyState(
        title: 'Команда в Спринте 10',
        icon: Icons.people_outline_rounded,
      ),
    );
  }
}
