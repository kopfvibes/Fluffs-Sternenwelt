import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/creative.dart';
import '../services/fluff_printing.dart';
import '../widgets/common.dart';
import '../widgets/pro_access.dart';
import 'parents_screen.dart';

class ProPage extends StatefulWidget {
  const ProPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<ProPage> createState() => _ProPageState();
}

class _ProPageState extends State<ProPage> {
  final code = TextEditingController();
  bool checking = false;
  String? error;
  @override
  void dispose() { code.dispose(); super.dispose(); }
  Future<void> activateCode() async {
    if (checking) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { checking = true; error = null; });
    try {
      await widget.controller.activatePro(code.text);
      if (mounted) {
        code.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fluff Pro ist für alle Kinderprofile freigeschaltet.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e is FormatException ? e.message :
          'Der Code konnte nicht gespeichert werden. Bitte versuche es noch einmal.');
      }
    } finally { if (mounted) setState(() => checking = false); }
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    ScreenTitle('Fluff Pro'),
    Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        FluffSprite(pose: 'proud', size: 170, animate: widget.controller.data.motion),
        Text(widget.controller.proActive ? 'Die Entdeckerwelt ist geöffnet.' :
          'Mehr Raum zum Entdecken', textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const GlossyPanel(child: Text('• Sechs Lernspiele mit wechselnden Aufgaben\n'
          '• Malatelier mit zwölf Ausmal- und Mitmachseiten\n'
          '• Eigene Bilder speichern und als PDF ausgeben\n'
          '• Entdecker-Sticker für jedes Kinderprofil\n\n'
          'Ohne Werbung, ohne Zeitdruck und ohne Konto.')),
        const SizedBox(height: 20),
        if (!widget.controller.proActive) ...[
          const Text('Du hast einen Pro-Code erworben? Füge ihn hier ein. '
            'Er gilt für alle Kinderprofile dieser App.'),
          const SizedBox(height: 12),
          TextField(key: const ValueKey('pro-code'), controller: code,
            minLines: 3, maxLines: 5, autocorrect: false,
            decoration: InputDecoration(labelText: 'Dein Pro-Code', errorText: error)),
          const SizedBox(height: 14),
          GlossyButton(checking ? 'Code wird geprüft …' : 'Pro-Code aktivieren',
            key: const ValueKey('activate-pro'), onPressed: checking ? null : activateCode),
          const SizedBox(height: 16),
          const Text('Bewahre deinen Code auf. Nach einer Neuinstallation kannst du '
            'ihn erneut eingeben. In der App wird kein Kauf ausgelöst.'),
        ] else ...[
          const Icon(Icons.verified_rounded, color: green, size: 54),
          const Text('Pro aktiv · Familienlizenz', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        ],
      ])),
  ]);
}

class PrintBookPage extends StatefulWidget {
  const PrintBookPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<PrintBookPage> createState() => _PrintBookPageState();
}

class _PrintBookPageState extends State<PrintBookPage> {
  int page = 1;
  bool working = false;
  Future<void> output({bool all = false, bool share = false}) async {
    if (working || !widget.controller.proActive) return;
    setState(() => working = true);
    await act(context, () async {
      final bytes = await FluffPrinting.book(all ? List.generate(12, (i) => i + 1) : [page]);
      if (!widget.controller.proActive) return;
      widget.controller.externalFilePicker = true;
      try {
        await FluffPrinting.output(bytes, filename: all ? 'Fluffs-Mal-und-Mitmachbuch.pdf'
          : 'Fluff-Ausmalbild-$page.pdf', share: share);
      } finally { widget.controller.externalFilePicker = false; }
    });
    if (mounted) setState(() => working = false);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.controller,
    builder: (context, _) => Column(children: [
    ScreenTitle('Malbuch zum Drucken'),
    Expanded(child: !widget.controller.proActive
      ? ProAccessPanel(forParents: true, onOpenPro: () => pushParent(context,
          widget.controller, () => ProPage(controller: widget.controller)))
      : ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      children: [
        Text(coloringTitles[page - 1], textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Image.asset(coloringAsset(page), height: 340, fit: BoxFit.contain),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(tooltip: 'Vorige Seite', onPressed: page == 1 ? null :
            () => setState(() => page--), icon: const Icon(Icons.chevron_left_rounded)),
          Text('Seite $page von 12'),
          IconButton(tooltip: 'Nächste Seite', onPressed: page == 12 ? null :
            () => setState(() => page++), icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        GlossyButton('Diese Seite drucken', onPressed:
          working ? null : () => output()),
        const SizedBox(height: 11),
        GlossyButton('Diese Seite als PDF speichern', color: green, onPressed:
          working ? null : () => output(share: true)),
        const SizedBox(height: 11),
        GlossyButton('Ganzes Malbuch als PDF', onPressed:
          working ? null : () => output(all: true, share: true)),
        if (working) const Padding(padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator())),
      ])),
  ]));
}
