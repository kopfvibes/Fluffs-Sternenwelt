# Fluffs Sternenwelt 5

Deutschsprachige Android-App fuer Familien. Fluff begleitet Kinder durch Alltagsaufgaben, Gefuehle und kleine Entdeckungen. Figuren, Animationen und alle bisherigen Aufgaben aus Version 4 bleiben erhalten.

## Neu in Version 5

- Sechs Pro-Lernspiele: Paare finden, Sterne zaehlen, Formen entdecken, Muster weiterdenken, Gefuehle verstehen und Gemeinsam handeln.
- Wechselnde Aufgaben und altersabhaengige Schwierigkeit fuer Zahlen, Muster und Paare. Kein Timer und keine Bestrafung bei falschen Antworten.
- Deutsche Vorlesefunktion fuer Fragen und Antwortmoeglichkeiten mit der auf dem Geraet verfuegbaren deutschen Text-zu-Sprache-Stimme. Bisherige Fluff-Aufnahmen bleiben eingebunden.
- Entdecker-Sticker und Spielabschluesse werden pro Kinderprofil gespeichert und veraendern die Sterne fuer Alltagsaufgaben nicht.
- Malatelier: freies Malen, zwoelf Mal- und Mitmachvorlagen, Farben, Pinselgroesse, Rueckgaengig, Wiederholen und ein Album mit bis zu zwoelf Bildern pro Kind.
- Eigene Bilder als PDF ausgeben; Vorlagen einzeln oder als ganzes Buch drucken oder als PDF speichern.
- Pro-Familiencodes mit Ed25519-Signaturpruefung. Aktivierung, Drucken und Teilen liegen hinter der Eltern-PIN. Freies Malen und die erste Druckvorlage sind kostenlos.

## Starten

1. Die signierte APK auf einem ARM64-Android-Geraet ab Android 7 installieren.
2. Ein Kinderprofil und eine eigene vierstellige Eltern-PIN anlegen.
3. Die Entdeckerwelt unter Mehr oeffnen. Weitere Kinder, Aufgaben, Belohnungen und Tagesplaene liegen im Elternbereich.
4. Den erworbenen Familiencode unter Elternbereich > Fluff Pro aktivieren. Er gilt fuer alle Kinderprofile. Es gibt keine vorgegebene PIN.

Version 4 wurde mit einer Entwicklungssignatur verteilt. Die neue dauerhafte Release-Signatur kann diese Installation nicht ueberschreiben. Vor einem Wechsel die Sicherung unter Einstellungen speichern, gegebenenfalls v4 deinstallieren, v5 installieren und die Sicherung wiederherstellen. Spaetere Updates muessen denselben privaten Release-Schluessel verwenden.

## Daten und Lizenzen

Alle Profile, Tagesplaene, Sterne, Gefuehle, Spiele und Zeichnungen bleiben lokal in SQLite. Die App benoetigt kein Benutzerkonto. Die Datenbankdatei aus v4 bleibt erhalten; Sicherungen mit Schema 2 werden weiter unterstuetzt. Fehlende neue Felder erhalten sichere Standardwerte. Eine Deinstallation loescht lokale Daten.

Die Eltern-PIN ist gesalzen gehasht. Die Datenbank ist nicht vollstaendig verschluesselt. Nach fuenf falschen PIN-Versuchen folgt eine Wartezeit. Beim Wechsel zu einer anderen App wird der Elternbereich gesperrt, ausser waehrend eines ausdruecklich geoeffneten Druck- oder Dateidialogs.

Pro wird aus einem gueltig signierten Familiencode abgeleitet, niemals aus einem importierten Boolean. Private Lizenz- und Android-Schluessel werden nicht im Repository oder in der APK gespeichert. Familiencodes sind nicht geraetegebunden und koennen offline weder gesperrt noch auf eine einzelne Installation begrenzt werden.

Die App enthaelt keine Zahlungsabwicklung und wurde nicht im Play Store veroeffentlicht. Beim direkten APK-Vertrieb kann ein Shop den Kauf abwickeln; danach bekommt die Familie ihren individuellen Code. Store-Veroeffentlichung und gegebenenfalls Store-Abrechnung sind ein eigener Schritt.

## Bauen und pruefen

Flutter 3.35.7, Dart 3.9.2, Java 17 und das Android SDK werden verwendet.

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1 --dart-define=RENDER_PREVIEWS=true
flutter build apk --release --target-platform android-arm64
flutter build appbundle --release
```

CI erzeugt APK und AAB ohne privaten Schluessel. Die Ausgaben werden danach mit dem privaten Release-Schluessel des Besitzers signiert. Signiermaterial und Verkaeufercodes bleiben ausserhalb des oeffentlichen Repositorys.

Tests decken die bestehenden Ablaeufe sowie Pro-Sperre, Signaturpruefung, Migration, Kinderwechsel, Zeichnen, Sicherungen und PDF-Erstellung ab. previews/v5/ enthaelt echte Flutter-Ansichten. Automatisierte Pruefungen ersetzen keine abschliessende Erprobung von Audio, Druckdialog und Installation auf einem echten Telefon.
