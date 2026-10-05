import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/controller.dart';
import '../data/models.dart';
import '../widgets/common.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int period = 1;
  int _weekNumber(DateTime d) {
    final date = DateTime.utc(d.year, d.month, d.day);
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final first = DateTime.utc(thursday.year, 1, 1);
    return 1 + (thursday.difference(first).inDays / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, now = c.now;
    final from = period == 0
        ? monday(now)
        : period == 1
        ? DateTime(now.year, now.month)
        : DateTime(now.year);
    final until = period == 0
        ? addDays(from, 7)
        : period == 1
        ? DateTime(now.year, now.month + 1)
        : DateTime(now.year + 1);
    final earned = c.earnedSince(from, until: until);
    final bins = <({String label, int value})>[];
    if (period == 0) {
      for (var i = 0; i < 7; i++) {
        final d = addDays(from, i);
        bins.add((
          label: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][i],
          value: c.earnedSince(d, until: addDays(d, 1)),
        ));
      }
    } else if (period == 1) {
      for (var d = monday(from); d.isBefore(until); d = addDays(d, 7)) {
        final start = d.isBefore(from) ? from : d;
        final end = addDays(d, 7).isAfter(until) ? until : addDays(d, 7);
        bins.add((
          label: 'KW ${_weekNumber(d)}',
          value: c.earnedSince(start, until: end),
        ));
      }
    } else {
      for (var i = 1; i <= 12; i++) {
        final d = DateTime(now.year, i);
        bins.add((
          label: DateFormat('MMM', 'de_DE').format(d),
          value: c.earnedSince(d, until: DateTime(now.year, i + 1)),
        ));
      }
    }
    final moods = <String, int>{};
    for (final f in c.data.feelings.where(
      (f) =>
          f.childId == c.child.id &&
          f.date.compareTo(dateKey(from)) >= 0 &&
          f.date.compareTo(dateKey(until)) < 0,
    )) {
      moods[f.value] = (moods[f.value] ?? 0) + 1;
    }
    final ordered = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mood = ordered.isEmpty ? null : ordered.first.key;
    int planned = 0, done = 0;
    for (final entry in c.data.dailyPlans.entries) {
      final parts = entry.key.split('|');
      if (parts[0] != c.child.id ||
          parts[1].compareTo(dateKey(from)) < 0 ||
          parts[1].compareTo(dateKey(until)) >= 0) {
        continue;
      }
      planned += entry.value.length;
      done += entry.value
          .where(
            (id) => c.data.stars.any(
              (e) => e.id == c.taskKey(c.child.id, id, parts[1]),
            ),
          )
          .length;
    }
    final percentage = planned == 0 ? 0 : (done / planned * 100).round();
    final maximum = max(1, bins.fold<int>(0, (n, b) => max(n, b.value)));
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      children: [
        ScreenTitle('Statistiken', back: () => Navigator.maybePop(context)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xfff1f2f1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: InkWell(
                    key: ValueKey('stats-$i'),
                    onTap: () => setState(() => period = i),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: i == period
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [Color(0xff45c0ff), blue],
                              ),
                            )
                          : null,
                      child: Text(
                        ['Woche', 'Monat', 'Jahr'][i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: i == period ? Colors.white : ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            children: [
              GlossyPanel(
                radius: 25,
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gesammelte Sterne',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: largeText ? 175 : 142,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 21,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: gold,
                                  size: 45,
                                ),
                                const SizedBox(width: 9),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$earned',
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      period == 0
                                          ? 'Diese Woche'
                                          : period == 1
                                          ? '${DateFormat('MMMM', 'de_DE').format(now)} ${now.year}'
                                          : 'Jahr ${now.year}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: -23,
                            top: 0,
                            bottom: -9,
                            width: 158,
                            child: FluffSprite(
                              size: 159,
                              animate: c.data.motion,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: largeText ? 205 : 150,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: bins
                            .map(
                              (bin) => Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${bin.value}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff62718b),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      width: period == 2 ? 15 : 27,
                                      height: 7 + bin.value / maximum * 86,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(5),
                                            ),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xff8bdcff),
                                            Color(0xff2199ed),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: const Color(0xffa8d7f3),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      bin.label,
                                      style: TextStyle(
                                        fontSize: period == 2 ? 8 : 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GlossyPanel(
                      radius: 25,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Aufgaben geschafft',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: planned == 0 ? 0 : done / planned,
                                    color: green,
                                    backgroundColor: const Color(0xffedf7e0),
                                    strokeWidth: 10,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                FittedBox(
                                  child: Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$done von $planned',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlossyPanel(
                      radius: 25,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Stimmung',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xffff4995),
                            size: 74,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood == null
                                ? 'Noch kein Gefühl\ngespeichert'
                                : 'meist\n$mood',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
