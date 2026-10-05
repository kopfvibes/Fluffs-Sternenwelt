import 'package:flutter/material.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.controller});
  final AppController controller;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _form = GlobalKey<FormState>(),
      _name = TextEditingController(),
      _pin = TextEditingController(),
      _repeat = TextEditingController();
  int age = 7, avatar = 0;
  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: WorldBackground(
      scene: true,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Image.asset('assets/art/logo.png', height: 122),
            const SizedBox(height: 12),
            FluffSprite(size: 170, animate: widget.controller.data.motion),
            GlossyPanel(
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    const Text(
                      'Hallo, kleine Sternesammler!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ein Erwachsener richtet dein Profil und die Eltern-PIN ein.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const ValueKey('setup-name'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 36,
                      decoration: const InputDecoration(
                        labelText: 'Name des Kindes',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Bitte einen Namen eingeben.'
                          : null,
                    ),
                    Row(
                      children: [
                        const Text('Alter'),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: age,
                            items: List.generate(
                              17,
                              (i) => DropdownMenuItem(
                                value: i + 2,
                                child: Text('${i + 2} Jahre'),
                              ),
                            ),
                            onChanged: (v) => setState(() => age = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        3,
                        (i) => InkWell(
                          onTap: () => setState(() => avatar = i),
                          borderRadius: BorderRadius.circular(40),
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
                              size: 62,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('setup-pin'),
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Eigene Eltern-PIN: 4 Ziffern',
                      ),
                      validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '')
                          ? null
                          : 'Bitte vier Ziffern eingeben.',
                    ),
                    TextFormField(
                      controller: _repeat,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'PIN wiederholen',
                      ),
                      validator: (v) => v == _pin.text
                          ? null
                          : 'Die PINs stimmen nicht überein.',
                    ),
                    const SizedBox(height: 8),
                    GlossyButton(
                      'Los geht’s!',
                      key: const ValueKey('finish-setup'),
                      icon: Icons.arrow_forward_rounded,
                      onPressed: widget.controller.busy
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                act(
                                  context,
                                  () => widget.controller.setup(
                                    _name.text,
                                    age,
                                    avatar,
                                    _pin.text,
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
