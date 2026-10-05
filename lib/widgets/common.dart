import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/controller.dart';
import '../data/models.dart';

const ink = Color(0xff092653),
    blue = Color(0xff078dff),
    gold = Color(0xffffc629),
    cream = Color(0xfffff6dd),
    green = Color(0xff11c95b);
ThemeData fluffTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Nunito',
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    surface: cream,
  ),
  scaffoldBackgroundColor: cream,
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: ink,
      height: 1.12,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: ink,
      height: 1.15,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w800,
      color: ink,
      height: 1.2,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: ink,
      height: 1.25,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: ink,
      height: 1.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: ink,
      height: 1.25,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: .82),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: cream,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: ink,
    centerTitle: true,
    elevation: 0,
  ),
);

class ArtIcon extends StatelessWidget {
  const ArtIcon(this.name, {super.key, this.size = 40});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/art/icon-$name${const {'cinema', 'game', 'icecream', 'zoo'}.contains(name) ? '-v2' : ''}.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(this.child, {super.key, this.size = 44});
  final ChildProfile child;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xffd3edfa),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/art/avatar-${child.avatar % 3}.png',
        fit: BoxFit.cover,
      ),
    ),
  );
}

class WorldBackground extends StatelessWidget {
  const WorldBackground({
    super.key,
    this.scene = false,
    this.night = false,
    this.bedtime = false,
    this.warm = false,
    required this.child,
  });
  final bool scene, night, bedtime, warm;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: night ? Brightness.light : Brightness.dark,
      statusBarBrightness: night ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (scene)
          Image.asset(
            bedtime
                ? 'assets/art/evening-world.jpg'
                : 'assets/art/${night ? 'night-world' : 'day-world-v2'}.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        if (!scene)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .22, .50, 1],
                colors: [
                  warm ? const Color(0xfffffdf7) : const Color(0xffbfecff),
                  const Color(0xfffbfcf5),
                  const Color(0xfffff8e4),
                  const Color(0xfffff3d0),
                ],
              ),
            ),
          ),
        if (!scene)
          Positioned(
            top: 5,
            left: 10,
            child: Opacity(
              opacity: .10,
              child: Icon(Icons.star_rounded, color: gold, size: 44),
            ),
          ),
        if (!scene)
          Positioned(
            bottom: 80,
            right: -8,
            child: Opacity(
              opacity: .09,
              child: Icon(Icons.star_rounded, color: gold, size: 74),
            ),
          ),
        child,
      ],
    ),
  );
}

class GlossyPanel extends StatelessWidget {
  const GlossyPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (color ?? const Color(0xfffffef8)).withValues(alpha: .96),
          (color ?? cream).withValues(alpha: .94),
        ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: .86),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x150a2450),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class GlossyButton extends StatelessWidget {
  const GlossyButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.color = gold,
    this.icon,
    this.small = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final c = onPressed == null ? const Color(0xffd2d6d5) : color;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: .25),
            offset: const Offset(0, 4),
            blurRadius: 1,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(c, Colors.white, .30)!, c],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .8),
          width: 1.4,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color == green ? Colors.white : ink,
          minimumSize: Size(double.infinity, small ? 42 : 54),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: small ? 9 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: small ? 15 : 18,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 9),
              Icon(icon, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class DoneCircle extends StatelessWidget {
  const DoneCircle(this.done, {super.key, this.size = 30});
  final bool done;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done ? green : Colors.white.withValues(alpha: .8),
      border: Border.all(
        color: done ? const Color(0xff0ac253) : const Color(0xffc8c8ce),
        width: 1.8,
      ),
      boxShadow: done
          ? const [BoxShadow(color: Color(0x2500a548), blurRadius: 4)]
          : null,
    ),
    child: done
        ? Icon(Icons.check_rounded, color: Colors.white, size: size * .72)
        : null,
  );
}

class ProgressStrip extends StatelessWidget {
  const ProgressStrip({
    super.key,
    required this.done,
    required this.total,
    this.caption = true,
  });
  final int done, total;
  final bool caption;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 31,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 15,
                  backgroundColor: const Color(0xffffedb4),
                  color: green,
                ),
              ),
            ),
            const Positioned(
              left: 0,
              child: Icon(Icons.star_rounded, color: gold, size: 43),
            ),
          ],
        ),
      ),
      if (caption)
        Text(
          '$done von $total Aufgaben geschafft',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
    ],
  );
}

Future<void> act(BuildContext context, Future<void> Function() callback) async {
  try {
    await callback();
  } catch (e) {
    if (context.mounted) {
      final message = e is StateError
          ? e.message
          : e is FormatException
          ? e.message
          : 'Das hat nicht geklappt. Deine bisherigen Daten bleiben erhalten.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

Future<bool> confirm(BuildContext context, String title, String text) =>
    showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    ).then((v) => v ?? false);
Future<void> chooseChild(BuildContext context, AppController controller) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: cream,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const Text(
            'Kinderprofil wechseln',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final child in controller.data.children)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlossyPanel(
                onTap: controller.busy
                    ? null
                    : () => act(sheet, () async {
                        await controller.selectChild(child.id);
                        if (sheet.mounted) Navigator.pop(sheet);
                      }),
                child: Row(
                  children: [
                    ProfileAvatar(child, size: 54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        child.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DoneCircle(child.id == controller.child.id),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.back,
    this.leading,
    this.controller,
    this.night = false,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? back;
  final IconData? leading;
  final AppController? controller;
  final bool night;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(
      children: [
        Row(
          children: [
            if (back != null)
              SizedBox(
                width: 27,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: back,
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 32,
                    color: night ? Colors.white : ink,
                  ),
                ),
              ),
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(leading, size: 30, color: gold),
              ),
            Expanded(
              child: Text(
                title,
                textAlign:
                    back != null ||
                        (controller == null && title != 'Elternbereich')
                    ? TextAlign.center
                    : TextAlign.left,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: night ? Colors.white : ink,
                  height: 1.12,
                ),
              ),
            ),
            if (controller != null)
              Semantics(
                label: 'Kinderprofil wechseln',
                button: true,
                child: InkWell(
                  onTap: () => chooseChild(context, controller!),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 116),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfileAvatar(controller!.child, size: 29),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            controller!.child.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (trailing != null) trailing!,
            if (back != null && controller == null && trailing == null)
              const SizedBox(width: 27),
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: night ? Colors.white : ink,
              ),
            ),
          ),
      ],
    ),
  );
}

class ChildNavigationBar extends StatelessWidget {
  const ChildNavigationBar({
    super.key,
    required this.index,
    required this.onSelect,
  });
  final int index;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xfffffcf5).withValues(alpha: .97),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x180a2751),
          blurRadius: 9,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Row(
          children: List.generate(5, (i) {
            final labels = ['Start', 'Aufgaben', 'Sterne', 'Gefühle', 'Mehr'];
            final icons = [
              Icons.home_rounded,
              Icons.assignment_turned_in_outlined,
              Icons.star_border_rounded,
              Icons.favorite_border_rounded,
              Icons.menu_rounded,
            ];
            final active = [
              Icons.home_rounded,
              Icons.assignment_turned_in_rounded,
              Icons.stars_rounded,
              Icons.favorite_rounded,
              Icons.menu_rounded,
            ];
            return Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: InkWell(
                  key: ValueKey('nav-$i'),
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          i == index ? active[i] : icons[i],
                          size: 27,
                          color: i == index ? blue : const Color(0xff9198a4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          labels[i],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: i == index
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: i == index ? blue : ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class FluffSprite extends StatefulWidget {
  const FluffSprite({
    super.key,
    this.pose = 'idle',
    this.size = 260,
    this.animate = true,
    this.onTap,
    this.faceOnly = false,
  });
  final String pose;
  final double size;
  final bool animate, faceOnly;
  final VoidCallback? onTap;
  @override
  State<FluffSprite> createState() => _FluffSpriteState();
}

class _FluffSpriteState extends State<FluffSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;
  DateTime? tapped;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    );
    if (widget.animate) animation.repeat();
  }

  @override
  void didUpdateWidget(FluffSprite old) {
    super.didUpdateWidget(old);
    if (widget.animate && !animation.isAnimating) animation.repeat();
    if (!widget.animate) {
      animation.stop();
      animation.value = 0;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  String frame(double t) {
    if (widget.pose == 'celebrate') return 'celebrate-v2';
    if (widget.pose != 'idle') return widget.pose;
    if (!widget.animate) return 'idle';
    if (t > .84 && t < .88) return 'blink';
    if (t < .14 || (t > .24 && t < .33)) return 'wave-up';
    if (t >= .14 && t <= .24) return 'wave-out';
    return 'idle';
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Fluff, dein blauer Begleiter',
    child: GestureDetector(
      onTap: widget.faceOnly || (!widget.animate && widget.onTap == null)
          ? null
          : () {
              if (widget.animate) setState(() => tapped = DateTime.now());
              widget.onTap?.call();
            },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final breath = widget.animate ? sin(t * pi * 4) : 0.0;
          final excited =
              widget.animate &&
              tapped != null &&
              DateTime.now().difference(tapped!).inMilliseconds < 1200;
          final bounce = excited
              ? sin(t * pi * 26).abs() * 18
              : widget.pose == 'celebrate'
              ? breath * 6
              : breath * 2;
          final Widget art = widget.pose == 'welcome'
              ? _WelcomePuppet(
                  size: widget.size,
                  angle: widget.animate ? sin(t * pi * 8) * .10 : 0,
                )
              : Image.asset(
                  'assets/art/fluff-${frame(t)}.png',
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                );
          return Transform.translate(
            offset: Offset(0, -bounce),
            child: Transform.rotate(
              angle: excited
                  ? sin(t * pi * 26) * .035
                  : widget.pose == 'celebrate' && widget.animate
                  ? breath * .022
                  : 0,
              child: Transform.scale(
                scale: 1 + breath * .008,
                child: widget.faceOnly
                    ? LayoutBuilder(
                        builder: (context, bounds) {
                          final side = bounds.maxWidth * 1.65;
                          return ClipRect(
                            child: OverflowBox(
                              maxWidth: side,
                              maxHeight: side,
                              alignment: Alignment.topCenter,
                              child: Transform.translate(
                                offset: Offset(0, -side * .12),
                                child: SizedBox(
                                  width: side,
                                  height: side,
                                  child: art,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : art,
              ),
            ),
          );
        },
      ),
    ),
  );
}

class StarJar extends StatelessWidget {
  const StarJar({super.key, required this.count, this.animate = true});
  final int count;
  final bool animate;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: .72,
    child: LayoutBuilder(
      builder: (context, b) {
        final n = min(count, 34);
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/art/empty-jar.png',
                fit: BoxFit.contain,
              ),
            ),
            for (var i = 0; i < n; i++)
              Positioned(
                left: b.maxWidth * (.18 + (i % 5) * .135) + sin(i * 4.7) * 4,
                bottom:
                    b.maxHeight * (.13 + (i ~/ 5) * .077) + cos(i * 2.9) * 4,
                child: Transform.rotate(
                  angle: sin(i * 2.7) * .20,
                  child: Container(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x75ffd236),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ArtIcon('star', size: b.maxWidth * .19),
                  ),
                ),
              ),
            Positioned(
              left: b.maxWidth * .14,
              top: b.maxHeight * .36,
              bottom: b.maxHeight * .16,
              child: Container(
                width: b.maxWidth * .038,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

// Der rechte Arm wird am Schulterpunkt bewegt. Das Originalbild bleibt unverändert.
class _WelcomePuppet extends StatelessWidget {
  const _WelcomePuppet({required this.size, required this.angle});
  final double size, angle;
  @override
  Widget build(BuildContext context) {
    Widget art() => Image.asset(
      'assets/art/fluff-welcome.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipPath(clipper: const _ArmClipper(body: true), child: art()),
          Transform.rotate(
            angle: angle,
            alignment: const Alignment(.49, .10),
            child: ClipPath(
              clipper: const _ArmClipper(body: false),
              child: art(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArmClipper extends CustomClipper<Path> {
  const _ArmClipper({required this.body});
  final bool body;
  @override
  Path getClip(Size s) {
    final arm = Path()
      ..moveTo(s.width * .73, s.height * .555)
      ..lineTo(s.width * .80, s.height * .39)
      ..lineTo(s.width * .82, s.height * .32)
      ..lineTo(s.width, s.height * .32)
      ..lineTo(s.width, s.height * .54)
      ..lineTo(s.width * .89, s.height * .60)
      ..lineTo(s.width * .80, s.height * .625)
      ..close();
    return body
        ? Path.combine(
            PathOperation.difference,
            Path()..addRect(Offset.zero & s),
            arm,
          )
        : arm;
  }

  @override
  bool shouldReclip(_ArmClipper old) => old.body != body;
}
