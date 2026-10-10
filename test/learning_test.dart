import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffs_sternenwelt/data/discovery.dart';
import 'package:fluffs_sternenwelt/widgets/learning_boards.dart';

void main() {
  test('Counting each item once links the last number to the whole set', () {
    final p = ExplorationProgress(4);
    expect(p.touch(2), isTrue);
    expect(p.touch(2), isFalse);
    expect(p.touch(-1), isFalse);
    expect(p.touch(4), isFalse);
    expect(p.numberAt(2), 1);
    expect(p.ready, isFalse);
    for (final i in [0,3,1]) { expect(p.touch(i), isTrue); }
    expect(p.ready, isTrue);
    expect(p.numberAt(1), 4);
    expect(p.next, -1);
  });
  test('Pattern inspection follows the actual left to right unit', () {
    final p = ExplorationProgress(3, ordered: true);
    expect(p.touch(1), isFalse);
    expect(p.touch(0), isTrue);
    expect(p.touch(0), isFalse);
    expect(p.touch(2), isFalse);
    expect(p.touch(1), isTrue);
    expect(p.touch(2), isTrue);
    expect(p.ready, isTrue);
  });
  test('Patterns vary the missing phase and repeat the same unit', () {
    final factory = GameFactory(random: Random(61));
    final phases = <int, Set<int>>{};
    for (var i = 0; i < 500; i++) {
      final q = factory.question('patterns', 8);
      final symbols = q.symbols;
      expect(q.answers[q.correct], q.unit[symbols.length % q.unit.length]);
      for (var j = 0; j < symbols.length; j++) {
        expect(symbols[j], q.unit[j % q.unit.length]);
      }
      phases.putIfAbsent(q.unit.length, () => {}).add(symbols.length % q.unit.length);
    }
    expect(phases[2], {0,1});
    expect(phases[3], {0,1,2});
    for (var i = 0; i < 100; i++) {
      expect(factory.question('patterns', 4).unit.length, 2);
    }
  });
  test('Help reduces the next challenge and independent practice raises it within age', () {
    for (final age in [3,5,8]) {
      final j = LearningJourney(age);
      expect(j.challengeAge, lessThanOrEqualTo(4));
      j.complete(); j.complete();
      expect(j.challengeAge, lessThanOrEqualTo(age));
      if (age >= 5) expect(j.challengeAge, inInclusiveRange(5,6));
      j.complete(); j.complete();
      expect(j.challengeAge, age);
      j.help(); j.complete();
      expect(j.independent, 0);
      expect(j.challengeAge, lessThanOrEqualTo(4));
    }
  });
  test('A short learning journey avoids repeated feeling and action stories', () {
    for (final game in ['feelings','kindness']) {
      final j = LearningJourney(5);
      final f = GameFactory(random: Random(13));
      final ids = List.generate(5, (_) => j.next(f,game).id);
      expect(ids.toSet().length, 5);
    }
  });
  test('Every personal feeling including uncertainty is valid', () {
    for (final q in feelingQuestions) {
      expect(q.personalFeeling, isTrue);
      expect(q.visual, '💙');
      expect(q.answers, contains('Weiß ich noch nicht'));
      for (var i=0; i<q.answers.length; i++) { expect(q.accepts(i), isTrue); }
      expect(q.accepts(-1), isFalse);
      expect(q.accepts(q.answers.length), isFalse);
    }
  });
  test('Shuffling preserves exploration and role play metadata', () {
    final f = GameFactory(random: Random(73));
    for (final game in ['shapes','patterns','feelings','kindness']) {
      final q=f.question(game,8);
      final mixed=q.shuffled(Random(42));
      expect(mixed.answers[mixed.correct],q.answers[q.correct]);
      expect(mixed.shape,q.shape);
      expect(mixed.unit,q.unit);
      expect(mixed.practice,q.practice);
      expect(mixed.personalFeeling,q.personalFeeling);
    }
  });
  test('All action stories include an actual phrase and a follow up situation', () {
    for (final q in kindnessQuestions) {
      expect(q.personalFeeling,isFalse);
      expect(q.practice,isNotNull);
      expect(q.practice!.phrase,isNotEmpty);
      expect(q.practice!.prompt,isNotEmpty);
      expect(q.practice!.answers.toSet().length,2);
      expect(q.practice!.explanation,isNotEmpty);
      expect(q.accepts(1),isFalse);
    }
  });
  test('Shape touch targets distinguish corners from outer star tips', () {
    for (final shape in shapeIds) {
      final n=switch(shape) {'circle'=>1,'triangle'=>3,'square'=>4,_=>5};
      final points=shapePoints(shape,264);
      expect(points.length,n);
      for (final point in points) {
        expect(point.dx,inInclusiveRange(25,239));
        expect(point.dy,inInclusiveRange(25,239));
      }
      if (shape=='square') {
        final sides=List.generate(4,(i)=>(points[i]-points[(i+1)%4]).distance);
        for (final side in sides) { expect(side,closeTo(sides.first,.001)); }
      }
    }
    expect(lessonWord('shape.star.fact'),contains('innere'));
    expect(lessonWord('shape.circle.fact'),contains('keine Ecken'));
  });
}
