# Prüfung der Version 5.0.1+51

Stand: 10. Oktober 2026. Flutter 3.35.7, Dart 3.9.2, Java 17.

| Prüfung | Ergebnis |
| --- | --- |
| Statische Dart-Prüfung | `flutter analyze`: keine Probleme |
| Gesamtlauf | 51 Tests bestanden; alle 35 bisherigen Tests plus 16 Prüfungen für Entdeckerwelt, Pro und Malatelier |
| Zugänge ohne Pro | Malatelier, freies Malen, Album, Vorlagen und sämtliche Druckzugänge gesperrt; keine Malbild-Vorschauen sichtbar |
| Elternbereich | Gesperrte Druckkachel führt zur Pro-Aktivierung; direkte Druckseite bleibt ebenfalls gesperrt |
| Lizenzwechsel | Bereits geöffnete Druck- und Zeichenansichten sperren nach Wiederherstellung einer Sicherung ohne gültige Lizenz; Bilder bleiben gespeichert und öffnen nach erneuter Aktivierung |
| Pro und Daten | Signaturen, abgewiesene gefälschte Codes, Neustart, v4-Migration, Kinderwechsel und Sicherungen geprüft |
| Bedienung | Quiz mit fünf Runden, Memory mit Fehlversuch und vollständigem Abschluss, Zeichnen bei 320 Pixeln mit großer Schrift geprüft |
| Druckausgabe | Alle zwölf mitgelieferten Vorlagen erzeugen eine PDF |
| Darstellung | Zwölf v5-Ansichten gerendert; drei neue Sperransichten visuell geprüft |
| Android | APK und AAB erfolgreich gebaut; Version 5.0.1, Build 51, API 24 bis Ziel-API 36, ARM64 |
| Signaturen | APK v2/v3 mit `apksigner verify`; AAB mit `jarsigner -verify` geprüft |
| Inhalt | Paket, Version, Buildnummer, Mindest-Android, Release-Modus und ARM64 direkt in der APK geprüft; 83 Bild-, Audio- und Schriftdateien bytegleich zum Quellcode |
| Native Bibliotheken | AAB-Bibliotheken für mindestens 16-KB-Seiten ausgerichtet |

[Erfolgreicher Build und Testlauf](https://github.com/kopfvibes/Fluffs-Sternenwelt/actions/runs/38029479577).
Geprüfter Funktionsstand: `e7c0f6728e704783f266326f3925914d7288e70e`. Die anschließende Dokumentation ändert keinen App-Code.

APK: `39364449` Bytes, SHA-256 `a98168dc0656873f2acc92c4676c1f9925496f78b57cf606927061ca138170ef`.
AAB: `34709007` Bytes, SHA-256 `0fc30069eec5dd6f3a3f591dfa6cdf33f3fa5467eed5c8426758dbe15b845433`.
Android-Zertifikat: SHA-256 `e7a52a2378a10fa7794d15a6a11b64e8c6e678994dd00dbba70801f7128715e5`.

Die private Lizenzsignierung und der Android-Keystore liegen außerhalb des Repositorys. Pro wird offline aus einem signierten Familiencode abgeleitet. Automatische Zahlungen, Abos und eine Play-Store-Veröffentlichung sind nicht eingerichtet. Version 5.0.1 verwendet denselben dauerhaften Release-Schlüssel wie 5.0.0 und kann diese Version als Update ersetzen.

Die bisherigen Fluff-Aufnahmen sind erhalten. Neue Fragen nutzen die auf dem Gerät installierte deutsche Text-zu-Sprache-Stimme. Installation, Audio, SQLite, Dateiauswahl und die externen Druckdialoge sind noch auf einem echten Telefon zu erproben. Die bisherigen Profile lassen sich über eine v4-Sicherung übernehmen. Wegen der neuen Release-Signatur beim ersten Wechsel von v4 vor einer nötigen Deinstallation unbedingt die Sicherung außerhalb der App speichern.
