# Fluffs Sternenwelt 5

Deutschsprachige Android-App fuer Familien. Fluff begleitet Kinder durch Alltagsaufgaben, Gefuehle und kleine Entdeckungen. Figuren, Animationen und alle bisherigen Aufgaben aus Version 4 bleiben erhalten.

## Neu in Version 5

- Sechs Pro-Lernspiele: Paare finden, Sterne zaehlen, Formen entdecken, Muster weiterdenken, Gefuehle verstehen und Gemeinsam handeln.
- Lernbegleitung ab Version 5.1: Fluff erklaert das Lernziel, macht Hilfen vor und fasst die Uebung zusammen. Sterne werden einzeln angetippt und gezaehlt; Formen an Ecken und Spitzen untersucht; wiederkehrende Mustergruppen erkundet.
- Memory bleibt im Tempo des Kindes: falsche Paare bleiben bis zum bewussten Zudecken sichtbar. Fluff kann ein Paar vormachen, ohne es als gefunden zu werten.
- Gefuehle sind keine Richtig-falsch-Fragen. Alle Gefuehlswoerter und Ungewissheit sind erlaubt. Danach werden ruhiges Atmen, ein Hilfesatz oder eine selbstbestimmte Pause geuebt. Diese fiktiven Antworten werden nicht als echte Gefuehlseintraege gespeichert.
- Zehn Alltagssituationen enthalten Satzuebungen und eine Anschlussfrage fuer Grenzen, Hilfe und respektvolle Reaktionen. Kein Mikrofon und keine Aufnahme des Kindes.
- Wechselnde Aufgaben und altersabhaengige Schwierigkeit; bei Zahlen und Mustern passt sich die naechste Aufgabe an selbststaendige Versuche und benoetigte Hilfen an. Kein Timer und keine Bestrafung bei Fehlern.
- Fluffs gespeicherte deutsche Stimme liest alle Pro-Fragen, Antwortmoeglichkeiten und Rueckmeldungen vor. 302 lokale Aufnahmen begleiten auch das Malatelier, seine Vorlagen, Farben und das Speichern. Kein Internet und keine Geraetestimme erforderlich; vorhandene Fluff-Aufnahmen bleiben eingebunden.
- Entdecker-Sticker und Spielabschluesse werden pro Kinderprofil gespeichert und veraendern die Sterne fuer Alltagsaufgaben nicht.
- Malatelier: freies Malen, zwoelf Mal- und Mitmachvorlagen, Farben, Pinselgroesse, Rueckgaengig, Wiederholen und ein Album mit bis zu zwoelf Bildern pro Kind.
- Eigene Bilder als PDF ausgeben; Vorlagen einzeln oder als ganzes Buch drucken oder als PDF speichern.
- Pro-Familiencodes mit Ed25519-Signaturpruefung. Das gesamte Malatelier, Bildvorschauen, das Bilderalbum und alle Druckvorlagen erfordern Pro, auch im Elternbereich. Aktivierung, Drucken und Teilen liegen zusaetzlich hinter der Eltern-PIN.

## Einheitliche Fluff-Stimme

Die bestehende HeyGen-Stimme "Fluff" (siehe `pro-voice-manifest.json`) ist auch die
Quelle der 302 offline gespeicherten Lernspiel-Aufnahmen. Weitere feste
Geschichten und App-Erklaerungen werden als **separate, lokal gebuendelte
Audioclips** aus derselben Stimme erzeugt. Ein anderes Android-TTS-Pitch ist
**nicht** dieselbe Stimme.

Die Vorbereitung fuer diesen erweiterten Offline-Sprachsatz liegt unter
`voice/fluff_narration_lines.json` und `scripts/build_fluff_voice_pack.py`.
Der Generator ist standardmaessig ein **Dry Run**, loest also keine
kostenpflichtige Spracherzeugung aus. Fuer eine echte Produktion benoetigt
man einen privaten HeyGen-API-Key in `HEYGEN_API_KEY` und muss ausdruecklich
`--generate` angeben. Beispiel:

```bash
python3 scripts/build_fluff_voice_pack.py
HEYGEN_API_KEY=... python3 scripts/build_fluff_voice_pack.py --generate
```

Nach der Generierung die geaenderten `assets/audio/narration/`-Dateien und
`lib/services/offline_fluff_narration.dart` committen und die CI ausfuehren.
Der API-Key gehoert niemals in Flutter, Git oder die APK. Die App sendet
**keine** privaten Kinderdaten an HeyGen. Eltern-eigene, neue Aufgaben und
abweichende Sternestaende koennen nicht durch feste Aufnahmen vollstaendig
abgedeckt werden; dafuer ist eine separat freizugebende, abgesicherte
Online-Spracherzeugung oder weiterhin die Systemstimme notwendig.

## Fluffs Geschichtenwald (Version 5.3)

60 unterschiedliche, liebevolle Mini-Geschichten sind fest in der App enthalten.
Je Kalendertag (ab dem 21.10.2026) wartet eine neue Geschichte mit
**drei Szenen**, zwei sicheren Mitmach-Moeglichkeiten und einer nachvollziehbaren
Loesung. Die Figur Fluff bleibt die bereits vorhandene originale App-Figur.
Der Zauberwald benutzt die vorhandene Nachtwald-Grafik, Sterne und warme
Goldakzente als Stilvorlage; **60 separate neue Szenenillustrationen wurden
nicht generiert**. Die Kinder koennen geloeste Geschichten aus ihrem eigenen
Geschichtenschatz erneut oeffnen. Fortschritt wird pro Kind lokal gespeichert,
bleibt in Backups erhalten und vergibt **keine Belohnungssterne**.

Die Vorlesefunktion verwendet Fluffs original aufgenommene Stimme, **wenn**
eine passende Audioaufnahme als Asset vorhanden ist. Der Offline-Sprachkatalog
`voice/fluff_narration_lines.json` wurde fuer alle 60 Geschichten erweitert.
Diese neuen gesprochenen Geschichten sind **noch nicht aufgenommen** und werden
bis zum explizit freigegebenen Ton-Generierungslauf ueber die deutsche
Geraetestimme vorgelesen. Der Ton-Generator laeuft niemals ungefragt im CI.

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

Tests decken die bestehenden Ablaeufe sowie Pro-Sperre, Signaturpruefung, Migration, Kinderwechsel, Zeichnen, Sicherungen und PDF-Erstellung ab. Zusaetzliche Audio-Tests pruefen die vollstaendige Aufnahmeabdeckung, die Reihenfolge der Antworten sowie Abbruch beim Ausschalten und bei neuen Aktionen. previews/v5/ enthaelt echte Flutter-Ansichten. Automatisierte Pruefungen ersetzen keine abschliessende Erprobung von Audio, Druckdialog und Installation auf einem echten Telefon.

Die Lernablaufe orientieren sich an angeleitetem Spiel mit Modell, Hinweis und kindlicher Entscheidung (NAEYC: https://www.naeyc.org/node/3812) sowie an der Zuordnung eines Zahlworts zu jedem Objekt und der Bedeutung der letzten Zahl fuer die Menge (EEF: https://educationendowmentfoundation.org.uk/early-years/evidence-store/early-mathematics/teaching-association-between-number-and-quantity). Die App selbst ist nicht wissenschaftlich evaluiert.
