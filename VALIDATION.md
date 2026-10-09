# Prüfung der Version 5.0.0+50

Stand: 9. Oktober 2026. Flutter 3.35.7, Dart 3.9.2, Java 17.

| Prüfung | Ergebnis |
| --- | --- |
| Statische Dart-Prüfung | `flutter analyze`: keine Probleme |
| Gesamtlauf | 46 Tests bestanden; alle 35 bisherigen Tests plus elf Prüfungen für Entdeckerwelt, Pro und Malatelier |
| Pro und Daten | Signaturen, abgewiesene gefälschte Codes, Neustart, v4-Migration, Kinderwechsel und Sicherungen geprüft |
| Bedienung | Quiz mit fünf Runden, Memory mit Fehlversuch und vollständigem Abschluss, Pro-Sperre und Zeichnen bei 320 Pixeln mit großer Schrift geprüft |
| Druckausgabe | Alle zwölf mitgelieferten Vorlagen erzeugen eine PDF |
| Darstellung | Bestehende Ansichten und neun neue Ansichten als echte Flutter-Bilder gerendert; neue Symbole verwenden feste Grafiken |
| Android | APK und AAB erfolgreich gebaut; Version 5.0.0, Build 50, API 24 bis Ziel-API 36, ARM64 |
| APK-Signatur | Dauerhafte Release-Signatur, v2 und v3 mit `apksigner verify` geprüft |
| App-Bundle | JAR-Signatur mit `jarsigner -verify` geprüft |
| Inhalt | Paket, Version, Buildnummer, Mindest-Android, Release-Modus und ARM64 direkt in der APK geprüft; 83 Bild-, Audio- und Schriftdateien bytegleich zum Quellcode |

[Erfolgreicher Build und Testlauf](https://github.com/kopfvibes/Fluffs-Sternenwelt/actions/runs/37989190840).
Geprüfter Funktionsstand: `da3b626e39d3b7583d55595719716a8d56b0b5cd`. Die anschließende Dokumentation ändert keinen App-Code.

APK: `39298913` Bytes, SHA-256 `f4e5bfd83d6f0f5578dbcf5f658e50258aa2b0ba3c0cb6d7fc088d4c18f3feca`.
AAB: `34702346` Bytes, SHA-256 `87c1f7f4d9fd45b1e9e5c8eb0cc53a4239e555151dd8eecb3d8cbbcc38dce620`.
Android-Zertifikat: SHA-256 `e7a52a2378a10fa7794d15a6a11b64e8c6e678994dd00dbba70801f7128715e5`.

Die private Lizenzsignierung und der Android-Keystore liegen außerhalb des Repositorys. Pro wird offline aus einem signierten Familiencode abgeleitet. Automatische Zahlungen und eine Play-Store-Veröffentlichung sind nicht eingerichtet.

Die bisherigen Fluff-Aufnahmen sind erhalten. Neue Fragen nutzen die auf dem Gerät installierte deutsche Text-zu-Sprache-Stimme. Installation, Audio, SQLite, Dateiauswahl und die externen Druckdialoge wurden noch nicht auf einem echten Telefon erprobt. Die bisherigen Profile lassen sich über eine v4-Sicherung übernehmen. Wegen der neuen Release-Signatur vor einer nötigen Deinstallation unbedingt die Sicherung außerhalb der App speichern.
