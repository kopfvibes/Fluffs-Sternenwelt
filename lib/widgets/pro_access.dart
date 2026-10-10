import 'package:flutter/material.dart';
import 'common.dart';

class ProAccessPanel extends StatelessWidget {
  const ProAccessPanel({super.key, required this.onOpenPro,
    this.forParents = false});
  final VoidCallback onOpenPro;
  final bool forParents;

  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline_rounded, color: blue, size: 56),
      const SizedBox(height: 18),
      Text('Das Malatelier gehört zu Fluff Pro.', textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      Text(forParents
        ? 'Aktiviere deinen Familiencode, um das Malatelier, alle zwölf '
          'Malbuchseiten und die Druckfunktionen zu öffnen.'
        : 'Deine Eltern können das Malatelier und deine Bilder mit Fluff Pro öffnen.',
        textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GlossyButton(forParents ? 'Fluff Pro aktivieren' : 'Mit meinen Eltern öffnen',
        key: const ValueKey('open-pro-access'), onPressed: onOpenPro),
    ]),
  ));
}
