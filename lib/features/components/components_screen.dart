import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';

class ComponentsScreen extends StatelessWidget {
  const ComponentsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoon(
        title: 'Components',
        icon: Icons.widgets_outlined,
        note: 'Chair components grouped by sub-team, with photos.',
      );
}
