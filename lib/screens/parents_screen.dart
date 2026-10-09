import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../services/audio.dart';
import '../widgets/common.dart';
import 'extra_pages.dart';
import 'statistics.dart';
import 'pro_pages.dart';

Future<void> openParents(BuildContext context, AppController controller) async {
  FluffAudio.instance.stop();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (_) => ParentPinDialog(controller: controller),
  );
  if (accepted == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ParentRoot(controller: controller),
      ),
    );
  }
}

class ParentPinDialog extends StatefulWidget {
  const ParentPinDialog({super.key, required this.controller});
  final AppController controller;
  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  final pin = TextEditingController();
  String? error;
  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  void check() {
    if (widget.controller.verifyPin(pin.text)) {
      Navigator.pop(context, true);
    } else {
      setState(
        () => error = widget.controller.pinWait > 0
            ? 'Bitte warte ${widget.controller.pinWait} Sekunden.'
            : 'Die PIN stimmt nicht.',
      );
      pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Elternbereich'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Bitte gib deine Eltern-PIN ein.'),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('parent-pin'),
          controller: pin,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          onSubmitted: (_) => check(),
          decoration: InputDecoration(
            labelText: '4-stellige PIN',
            errorText: error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Abbrechen'),
      ),
      TextButton(
        key: const ValueKey('unlock-parents'),
        onPressed: check,
        child: const Text('Öffnen'),
      ),
    ],
  );
}

class ParentRoot extends StatefulWidget {
  const ParentRoot({super.key, required this.controller});
  final AppController controller;
  @override
  State<ParentRoot> createState() => _ParentRootState();
}

class _ParentRootState extends State<ParentRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        !widget.controller.externalFilePicker &&
        mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => parentPage(
    widget.controller,
    () => ParentHub(controller: widget.controller),
  );
}

Widget parentPage(AppController c, Widget Function() page) => AnimatedBuilder(
  animation: c,
  builder: (context, _) => Scaffold(
    body: WorldBackground(warm: true, child: SafeArea(child: page())),
  ),
);
Future<void> pushParent(
  BuildContext context,
  AppController c,
  Widget Function() page,
) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => parentPage(c, page)));

class ParentHub extends StatelessWidget {
  const ParentHub({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Elternbereich',
        trailing: IconButton(
          tooltip: 'Einstellungen',
          onPressed: () => pushParent(
            context,
            controller,
            () => SettingsPage(controller: controller),
          ),
          icon: const Icon(Icons.settings_rounded, color: blue, size: 30),
        ),
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, b) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            return GridView.count(
              padding: const EdgeInsets.fromLTRB(19, 7, 19, 20),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 15,
              childAspectRatio: textScale > 1.3 ? 0.49 : 1.00,
              children: [
                _tile(context, 'Fluff Pro', 'game',
                  () => ProPage(controller: controller)),
                _tile(context, 'Malbuch drucken', 'book',
                  () => PrintBookPage(controller: controller)),
                _tile(
                  context,
                  'Kinderprofile\nverwalten',
                  'profiles',
                  () => ProfilesPage(controller: controller),
                ),
                _tile(
                  context,
                  'Aufgaben\nverwalten',
                  'clipboard',
                  () => TaskManagerPage(controller: controller),
                ),
                _tile(
                  context,
                  'Belohnungen',
                  'gift',
                  () => RewardManagerPage(controller: controller),
                ),
                _tile(
                  context,
                  'Tagesplan',
                  'calendar',
                  () => DayPlanPage(
                    controller: controller,
                    allowEdit: true,
                    onEditPlan: (p) => editPlan(context, controller, p),
                  ),
                ),
                _tile(
                  context,
                  'Statistiken',
                  'stats',
                  () => StatisticsPage(controller: controller),
                ),
                _tile(
                  context,
                  'Einstellungen',
                  'settings',
                  () => SettingsPage(controller: controller),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
  Widget _tile(
    BuildContext context,
    String label,
    String icon,
    Widget Function() page,
  ) => GlossyPanel(
    radius: 25,
    padding: const EdgeInsets.all(11),
    onTap: () => pushParent(context, controller, page),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 69,
          child: Center(
            child: icon == 'profiles'
                ? Image.asset(
                    'assets/art/icon-family.png',
                    width: 70,
                    height: 67,
                    fit: BoxFit.contain,
                  )
                : icon == 'stats'
                ? const Icon(Icons.bar_chart_rounded, color: blue, size: 69)
                : icon == 'settings'
                ? const Icon(Icons.settings_rounded, color: blue, size: 65)
                : ArtIcon(icon, size: 64),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Kinderprofile',
        back: () => Navigator.maybePop(context),
        trailing: PopupMenuButton<String>(
          tooltip: 'Profil bearbeiten',
          onSelected: (id) {
            final child = controller.data.children.firstWhere(
              (c) => c.id == id,
            );
            editChild(context, controller, child);
          },
          itemBuilder: (_) => controller.data.children
              .map(
                (c) => PopupMenuItem(
                  value: c.id,
                  child: Text('${c.name} bearbeiten'),
                ),
              )
              .toList(),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 7, 19, 24),
          children: [
            for (final c in controller.data.children)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onLongPress: () => editChild(context, controller, c),
                  child: GlossyPanel(
                    radius: 25,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15,
                    ),
                    color: c.id == controller.child.id
                        ? const Color(0xffe3f6f4)
                        : null,
                    onTap: controller.busy
                        ? null
                        : () =>
                              act(context, () => controller.selectChild(c.id)),
                    child: Row(
                      children: [
                        ProfileAvatar(c, size: 70),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                              ),
                              Text(
                                '${c.age} Jahre',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: gold,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${controller.balance(c.id)} Sterne',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        DoneCircle(c.id == controller.child.id, size: 33),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 9),
            GlossyPanel(
              radius: 25,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              onTap: () => editChild(context, controller),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      color: Color(0xff8ca7bb),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 17),
                  const Expanded(
                    child: Text(
                      'Kind hinzufügen',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> editChild(
  BuildContext context,
  AppController c, [
  ChildProfile? existing,
]) async {
  final name = TextEditingController(text: existing?.name ?? '');
  int age = existing?.age ?? 7, avatar = existing?.avatar ?? 0;
  final form = GlobalKey<FormState>();
  bool saving = false;
  ModalRoute<dynamic>? ownerRoute;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cream,
    builder: (sheet) {
      ownerRoute ??= ModalRoute.of(sheet);
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null
                        ? 'Kind hinzufügen'
                        : 'Kinderprofil bearbeiten',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('child-name'),
                    controller: name,
                    maxLength: 36,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bitte einen Namen eingeben.'
                        : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: age,
                    decoration: const InputDecoration(labelText: 'Alter'),
                    items: List.generate(
                      17,
                      (i) => DropdownMenuItem(
                        value: i + 2,
                        child: Text('${i + 2} Jahre'),
                      ),
                    ),
                    onChanged: (v) => setState(() => age = v!),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (i) => InkWell(
                        onTap: () => setState(() => avatar = i),
                        borderRadius: BorderRadius.circular(36),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: avatar == i ? blue : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: ProfileAvatar(
                            ChildProfile(
                              id: 'preview',
                              name: '',
                              age: age,
                              avatar: i,
                              createdAt: '',
                            ),
                            size: 66,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlossyButton(
                    'Speichern',
                    key: const ValueKey('save-child'),
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            setState(() => saving = true);
                            await act(sheet, () async {
                              if (existing == null) {
                                await c.addChild(name.text, age, avatar);
                              } else {
                                await c.editChild(
                                  existing.id,
                                  name.text,
                                  age,
                                  avatar,
                                );
                              }
                              if (sheet.mounted) Navigator.pop(sheet);
                            });
                            if (sheet.mounted) setState(() => saving = false);
                          },
                  ),
                  if (existing != null)
                    TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (await confirm(
                                    sheet,
                                    'Profil löschen?',
                                    '${existing.name}, die Sterne, Wünsche und Gefühle dieses Profils werden gelöscht. Andere Kinder bleiben erhalten.',
                                  ) &&
                                  sheet.mounted) {
                                await act(sheet, () async {
                                  await c.removeChild(existing.id);
                                  if (sheet.mounted) Navigator.pop(sheet);
                                });
                              }
                            },
                      child: const Text(
                        'Dieses Profil löschen',
                        style: TextStyle(color: Color(0xffc72b43)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  await ownerRoute?.completed;
  name.dispose();
}

class TaskManagerPage extends StatelessWidget {
  const TaskManagerPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Aufgaben verwalten',
        back: () => Navigator.maybePop(context),
        trailing: IconButton(
          tooltip: 'Aufgabe hinzufügen',
          onPressed: () => editTask(context, controller),
          icon: const Icon(Icons.add_rounded, color: blue),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 3, 18, 22),
          children: [
            GlossyPanel(
              onTap: () => chooseChild(context, controller),
              child: Row(
                children: [
                  ProfileAvatar(controller.child),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Für ${controller.child.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final t in controller.data.tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: GlossyPanel(
                  padding: const EdgeInsets.all(10),
                  onTap: () => editTask(context, controller, t),
                  child: Row(
                    children: [
                      ArtIcon(t.icon, size: 43),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${t.time} · ${t.routine} · ${t.stars} Sterne\n${t.active ? 'Aktiv' : 'Ausgeschaltet'}${t.children.isEmpty ? ' · Alle Kinder' : ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Aufgaben-Aktionen',
                        onSelected: (v) async {
                          if (v == 'edit') {
                            editTask(context, controller, t);
                          } else if (v == 'undo') {
                            if (await confirm(
                                  context,
                                  'Heute zurücknehmen?',
                                  'Die Sterne für diese Aufgabe und nicht mehr gültige Missionsboni werden zurückgenommen.',
                                ) &&
                                context.mounted) {
                              act(context, () => controller.undoTask(t));
                            }
                          } else {
                            final copy = TaskItem.fromJson(t.toJson());
                            copy.active = !copy.active;
                            act(context, () => controller.saveTask(copy));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Bearbeiten'),
                          ),
                          PopupMenuItem(
                            value: 'active',
                            child: Text(
                              t.active ? 'Ausschalten' : 'Einschalten',
                            ),
                          ),
                          if (controller.done(t))
                            const PopupMenuItem(
                              value: 'undo',
                              child: Text('Heute zurücknehmen'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

Future<void> editTask(
  BuildContext context,
  AppController c, [
  TaskItem? existing,
]) async {
  final task = existing == null
      ? TaskItem(
          id: '',
          title: '',
          icon: 'tooth',
          time: '08:00',
          steps: ['Mach einen kleinen Schritt.', 'Du darfst dir Hilfe holen.'],
        )
      : TaskItem.fromJson(existing.toJson());
  final title = TextEditingController(text: task.title),
      time = TextEditingController(text: task.time),
      steps = TextEditingController(text: task.steps.join('\n'));
  bool allChildren = task.children.isEmpty, saving = false;
  final form = GlobalKey<FormState>();
  ModalRoute<dynamic>? ownerRoute;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cream,
    builder: (sheet) {
      ownerRoute ??= ModalRoute.of(sheet);
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    existing == null
                        ? 'Aufgabe hinzufügen'
                        : 'Aufgabe bearbeiten',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 17),
                  TextFormField(
                    controller: title,
                    maxLength: 65,
                    decoration: const InputDecoration(
                      labelText: 'Aufgabenname',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bitte einen Namen eingeben.'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: task.icon,
                    decoration: const InputDecoration(labelText: 'Symbol'),
                    items:
                        const [
                              'tooth',
                              'shirt',
                              'bowl',
                              'bag',
                              'gift',
                              'book',
                              'cutlery',
                              'teddy',
                              'bed',
                              'cinema',
                              'game',
                              'icecream',
                              'moon',
                              'zoo',
                              'clipboard',
                              'calendar',
                            ]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Row(
                                  children: [
                                    ArtIcon(v, size: 31),
                                    const SizedBox(width: 12),
                                    Text(iconLabel(v)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => task.icon = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: time,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            labelText: 'Uhrzeit · HH:MM',
                          ),
                          validator: (v) =>
                              RegExp(
                                r'^([01]\d|2[0-3]):[0-5]\d$',
                              ).hasMatch(v ?? '')
                              ? null
                              : 'Zum Beispiel 08:30',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: task.routine,
                          decoration: const InputDecoration(
                            labelText: 'Routine',
                          ),
                          items: const ['Morgen', 'Tag', 'Abend']
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => task.routine = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  DropdownButtonFormField<String>(
                    initialValue: task.skill,
                    decoration: const InputDecoration(labelText: 'Bereich'),
                    items: const [
                      DropdownMenuItem(value: 'alltag', child: Text('Alltag')),
                      DropdownMenuItem(
                        value: 'hilfe',
                        child: Text('Zu Hause helfen'),
                      ),
                      DropdownMenuItem(
                        value: 'lesen',
                        child: Text('Lesen oder Vorlesen'),
                      ),
                      DropdownMenuItem(
                        value: 'dranbleiben',
                        child: Text('Dranbleiben'),
                      ),
                    ],
                    onChanged: (v) => setState(() => task.skill = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: task.stars,
                    decoration: const InputDecoration(labelText: 'Sterne'),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1} ${i == 0 ? 'Stern' : 'Sterne'}'),
                      ),
                    ),
                    onChanged: (v) => setState(() => task.stars = v!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Wochentage',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Wrap(
                    spacing: 7,
                    children: List.generate(
                      7,
                      (i) => FilterChip(
                        label: Text(
                          ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][i],
                        ),
                        selected: task.days.contains(i + 1),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            task.days.add(i + 1);
                          } else {
                            task.days.remove(i + 1);
                          }
                        }),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Für alle Kinder'),
                    value: allChildren,
                    onChanged: (v) => setState(() {
                      allChildren = v;
                      task.children = v ? [] : [c.child.id];
                    }),
                  ),
                  if (!allChildren)
                    for (final child in c.data.children)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(child.name),
                        value: task.children.contains(child.id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            task.children.add(child.id);
                          } else {
                            task.children.remove(child.id);
                          }
                        }),
                      ),
                  TextFormField(
                    controller: steps,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Kleine Schritte · eine Zeile pro Schritt',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bitte eine Anleitung eingeben.'
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aufgabe aktiv'),
                    value: task.active,
                    onChanged: (v) => setState(() => task.active = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Im Tagesplan zeigen'),
                    value: task.showInPlan,
                    onChanged: (v) => setState(() => task.showInPlan = v),
                  ),
                  const SizedBox(height: 10),
                  GlossyButton(
                    'Speichern',
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            if (task.days.isEmpty ||
                                (!allChildren && task.children.isEmpty)) {
                              ScaffoldMessenger.of(sheet).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Wähle mindestens einen Wochentag und ein Kind.',
                                  ),
                                ),
                              );
                              return;
                            }
                            task.title = title.text.trim();
                            task.time = time.text.trim();
                            task.steps = steps.text
                                .split('\n')
                                .map((v) => v.trim())
                                .where((v) => v.isNotEmpty)
                                .toList();
                            setState(() => saving = true);
                            await act(sheet, () async {
                              await c.saveTask(task);
                              if (sheet.mounted) Navigator.pop(sheet);
                            });
                            if (sheet.mounted) setState(() => saving = false);
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  await ownerRoute?.completed;
  title.dispose();
  time.dispose();
  steps.dispose();
}

String iconLabel(String icon) =>
    const {
      'tooth': 'Zähne',
      'shirt': 'Kleidung',
      'bowl': 'Frühstück',
      'bag': 'Tasche',
      'gift': 'Aufräumen / Geschenk',
      'book': 'Buch',
      'cutlery': 'Tisch / Essen',
      'teddy': 'Kuscheltier',
      'bed': 'Bett',
      'cinema': 'Kino',
      'game': 'Spielzeug',
      'icecream': 'Eis',
      'moon': 'Abend',
      'zoo': 'Zoo',
      'clipboard': 'Aufgabe',
      'calendar': 'Kalender',
    }[icon] ??
    icon;

class RewardManagerPage extends StatelessWidget {
  const RewardManagerPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle(
        'Belohnungen',
        back: () => Navigator.maybePop(context),
        trailing: IconButton(
          tooltip: 'Belohnung hinzufügen',
          onPressed: () => editReward(context, controller),
          icon: const Icon(Icons.add_rounded, color: blue),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
          children: [
            if (controller.data.requests.any((r) => r.status == 'offen')) ...[
              const Text(
                'Wünsche freigeben',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final r in controller.data.requests.where(
                (r) => r.status == 'offen',
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlossyPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${controller.data.children.firstWhere((c) => c.id == r.childId).name}: ${r.title}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${r.cost} Sterne · verfügbar: ${controller.balance(r.childId)}',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => act(
                                        context,
                                        () => controller.decideRequest(
                                          r.id,
                                          'abgelehnt',
                                        ),
                                      ),
                                child: const Text('Ablehnen'),
                              ),
                            ),
                            Expanded(
                              child: GlossyButton(
                                'Freigeben',
                                color: green,
                                small: true,
                                onPressed: controller.busy
                                    ? null
                                    : () async {
                                        if (await confirm(
                                              context,
                                              'Wunsch erfüllen?',
                                              '${r.cost} Sterne werden einmalig abgezogen. Der Wunsch wird als erfüllt gespeichert.',
                                            ) &&
                                            context.mounted) {
                                          act(
                                            context,
                                            () => controller.decideRequest(
                                              r.id,
                                              'erfüllt',
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
            ],
            for (final reward in controller.data.rewards)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlossyPanel(
                  onTap: () => editReward(context, controller, reward),
                  child: Row(
                    children: [
                      ArtIcon(reward.icon, size: 47),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reward.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${reward.cost} Sterne · ${reward.active ? 'Aktiv' : 'Ausgeschaltet'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: blue),
                    ],
                  ),
                ),
              ),
            for (final r
                in controller.data.requests
                    .where((r) => r.status != 'offen')
                    .toList()
                    .reversed
                    .take(8))
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(r.title),
                subtitle: Text('${r.status} · ${r.cost} Sterne'),
              ),
          ],
        ),
      ),
    ],
  );
}

Future<void> editReward(
  BuildContext context,
  AppController c, [
  RewardItem? existing,
]) async {
  final reward = existing == null
      ? RewardItem(id: '', title: '', icon: 'gift', cost: 10)
      : RewardItem.fromJson(existing.toJson());
  final name = TextEditingController(text: reward.title),
      cost = TextEditingController(text: '${reward.cost}');
  final form = GlobalKey<FormState>();
  bool saving = false;
  ModalRoute<dynamic>? ownerRoute;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cream,
    builder: (sheet) {
      ownerRoute ??= ModalRoute.of(sheet);
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    existing == null
                        ? 'Belohnung hinzufügen'
                        : 'Belohnung bearbeiten',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: name,
                    maxLength: 65,
                    decoration: const InputDecoration(
                      labelText: 'Gemeinsamer Wunsch',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bitte einen Namen eingeben.'
                        : null,
                  ),
                  TextFormField(
                    controller: cost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sterne · 1 bis 999',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n == null || n < 1 || n > 999
                          ? 'Bitte 1 bis 999 Sterne eingeben.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: reward.icon,
                    decoration: const InputDecoration(labelText: 'Symbol'),
                    items:
                        const [
                              'gift',
                              'cinema',
                              'book',
                              'game',
                              'icecream',
                              'moon',
                              'zoo',
                              'calendar',
                              'teddy',
                            ]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Row(
                                  children: [
                                    ArtIcon(v, size: 32),
                                    const SizedBox(width: 10),
                                    Text(iconLabel(v)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => reward.icon = v!),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wunsch verfügbar'),
                    value: reward.active,
                    onChanged: (v) => setState(() => reward.active = v),
                  ),
                  const SizedBox(height: 13),
                  GlossyButton(
                    'Speichern',
                    onPressed: saving
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            reward.title = name.text.trim();
                            reward.cost = int.parse(cost.text);
                            setState(() => saving = true);
                            await act(sheet, () async {
                              await c.saveReward(reward);
                              if (sheet.mounted) Navigator.pop(sheet);
                            });
                            if (sheet.mounted) setState(() => saving = false);
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  await ownerRoute?.completed;
  name.dispose();
  cost.dispose();
}

Future<void> editPlan(
  BuildContext context,
  AppController c,
  PlanItem item,
) async {
  final plan = PlanItem.fromJson(item.toJson());
  final name = TextEditingController(text: plan.title),
      time = TextEditingController(text: plan.time);
  final form = GlobalKey<FormState>();
  ModalRoute<dynamic>? ownerRoute;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: cream,
    builder: (sheet) {
      ownerRoute ??= ModalRoute.of(sheet);
      return StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              0,
              22,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Planpunkt bearbeiten',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Bitte einen Namen eingeben.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: time,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Uhrzeit · HH:MM',
                    ),
                    validator: (v) =>
                        RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v ?? '')
                        ? null
                        : 'Zum Beispiel 07:30',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: plan.icon,
                    decoration: const InputDecoration(labelText: 'Symbol'),
                    items:
                        const [
                              'bed',
                              'tooth',
                              'bowl',
                              'bag',
                              'cutlery',
                              'book',
                              'gift',
                              'calendar',
                            ]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Row(
                                  children: [
                                    ArtIcon(v, size: 30),
                                    const SizedBox(width: 12),
                                    Text(iconLabel(v)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => plan.icon = v!),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Planpunkt anzeigen'),
                    value: plan.active,
                    onChanged: (v) => setState(() => plan.active = v),
                  ),
                  const SizedBox(height: 12),
                  GlossyButton(
                    'Speichern',
                    onPressed: c.busy
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            plan.title = name.text.trim();
                            plan.time = time.text.trim();
                            await act(sheet, () async {
                              await c.savePlan(plan);
                              if (sheet.mounted) Navigator.pop(sheet);
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  await ownerRoute?.completed;
  name.dispose();
  time.dispose();
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ScreenTitle('Einstellungen', back: () => Navigator.maybePop(context)),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(19, 0, 19, 22),
          children: [
            GlossyPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Fluff bewegt sich'),
                    subtitle: const Text('Winken, Blinzeln, Atmen und Jubeln'),
                    value: controller.data.motion,
                    onChanged: (v) =>
                        act(context, () => controller.settings(motion: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Fluff-Stimme und Sternklang'),
                    subtitle: const Text('Lokal gespeicherte Audiodateien'),
                    value: controller.data.sound,
                    onChanged: (v) =>
                        act(context, () => controller.settings(sound: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Sanfte Vibration'),
                    value: controller.data.haptics,
                    onChanged: (v) =>
                        act(context, () => controller.settings(haptics: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlossyPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: blue),
                    title: const Text('Eltern-PIN ändern'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _changePin(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt_rounded, color: blue),
                    title: const Text('Datensicherung speichern'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: controller.busy ? null : () => _export(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: blue),
                    title: const Text('Datensicherung wiederherstellen'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: controller.busy ? null : () => _restore(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const GlossyPanel(
              child: Text(
                'Profile, Sterne, Gefühle und Wünsche bleiben auf diesem Gerät. Ohne Datensicherung gehen sie bei einer Deinstallation verloren. Eine Sicherung enthält auch die gehashte Eltern-PIN.',
              ),
            ),
            const SizedBox(height: 15),
            GlossyPanel(
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Fluffs Sternenwelt',
                applicationVersion: '4.0.0',
                applicationIcon: const FluffSprite(size: 66, animate: false),
                children: const [
                  Text(
                    'Kleine Aufgaben. Große Schritte. Mit Fluff an deiner Seite.',
                  ),
                ],
              ),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline_rounded, color: blue),
                title: Text('Über Fluffs Sternenwelt'),
                trailing: Text('4.0.0'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
  Future<void> _changePin(BuildContext context) async {
    final pin = TextEditingController(), repeat = TextEditingController();
    final form = GlobalKey<FormState>();
    ModalRoute<dynamic>? ownerRoute;
    await showDialog<void>(
      context: context,
      builder: (dialog) {
        ownerRoute ??= ModalRoute.of(dialog);
        return AlertDialog(
          title: const Text('Neue Eltern-PIN'),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: '4 Ziffern'),
                  validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '')
                      ? null
                      : 'Bitte vier Ziffern eingeben.',
                ),
                TextFormField(
                  controller: repeat,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'PIN wiederholen',
                  ),
                  validator: (v) =>
                      v == pin.text ? null : 'Die PINs stimmen nicht überein.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => act(dialog, () async {
                if (!form.currentState!.validate()) return;
                await controller.changePin(pin.text);
                if (dialog.mounted) Navigator.pop(dialog);
              }),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
    await ownerRoute?.completed;
    pin.dispose();
    repeat.dispose();
  }

  Future<void> _export(BuildContext context) => act(context, () async {
    controller.externalFilePicker = true;
    try {
      final bytes = utf8.encode(controller.exportBackup());
      final file = await FilePicker.platform.saveFile(
        dialogTitle: 'Fluffs-Datensicherung speichern',
        fileName: 'Fluffs-Sicherung-${controller.today}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (file != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datensicherung gespeichert.')),
        );
      }
    } finally {
      controller.externalFilePicker = false;
    }
  });
  Future<void> _restore(BuildContext context) => act(context, () async {
    if (!await confirm(
          context,
          'Sicherung wiederherstellen?',
          'Der aktuelle Stand wird durch die ausgewählte Sicherung ersetzt. Danach gilt die Eltern-PIN aus der Sicherung.',
        ) ||
        !context.mounted) {
      return;
    }
    controller.externalFilePicker = true;
    try {
      final selected = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (selected == null) return;
      final f = selected.files.single;
      final bytes = f.bytes ?? await File(f.path!).readAsBytes();
      await controller.restoreBackup(utf8.decode(bytes));
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datensicherung wiederhergestellt.')),
        );
      }
    } finally {
      controller.externalFilePicker = false;
    }
  });
}
