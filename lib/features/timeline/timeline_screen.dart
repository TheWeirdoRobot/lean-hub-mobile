import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoon(
        title: 'Timeline',
        icon: Icons.view_timeline_outlined,
        note: 'A Gantt view of team tasks will live here.',
      );
}
