# Prüfung der Version 4.0.0+40

Stand: 4. Oktober 2026. Flutter 3.35.7, Dart 3.9.2.

| Prüfung | Ergebnis |
| --- | --- |
| Statische Dart-Prüfung | `flutter analyze --no-pub`: keine Probleme |
| Logik und Speicherung | 25 bestandene Tests mit MemoryRepository, einschließlich fehlgeschlagener Schreibvorgänge |
| Bedienung der echten App | 7 bestandene Widget-Tests: Einrichtung, PIN, Kinderwechsel, Aufgaben, Gefühle, Wunschfreigabe und Elternformulare |
| Darstellung und Bewegung | 3 bestandene Widget-Tests: zwölf Ansichten, 15 Ansichten bei 320 Pixeln und doppelter Schriftgröße, Bewegung ein/aus |
| Gesamtlauf | 35 Tests bestanden mit `flutter test --no-pub --concurrency=1` |
| Vorschau | Zwölf echte Flutter-Ansichten als PNG; 5,6 Sekunden Video aus 84 tatsächlich gerenderten Animationsbildern |
| Android-APK | Release-Build erfolgreich; App 4.0.0, Build 40, mindestens Android 7 (API 24), ARM64 |
| APK-Signatur und Inhalt | Signatur mit `apksigner verify` geprüft; ausschließlich ARM64-Bibliotheken und alle sieben überarbeiteten Bilder enthalten |

Die Vorschau verwendet erfundene Daten aus `test/fixtures.dart`. In der installierten App werden das erste Kind und eine eigene Eltern-PIN beim Start angelegt. Sternzahlen, Datum und Statistiken hängen im echten Betrieb von den gespeicherten Daten ab.

Die automatisierten Prüfungen ersetzen noch keinen Test auf einem echten Android-Gerät. SQLite, Dateiauswahl, Audio und Vibration sind eingebunden, wurden in dieser Umgebung aber nicht auf einem Telefon erprobt. Die Ansichten orientieren sich an der Bildvorlage; eine Pixelgleichheit aller Figuren, Hintergründe und Displaygrößen ist nicht bestätigt.

APK-Datei: `Fluffs-Sternenwelt-v4.apk`, 35937631 Bytes. SHA-256: `23ce7db564c79af6dcfa74a9589e9306e1102220ce87d77049c10b11d3177eac`. Die APK verwendet eine Entwicklungssignatur.
