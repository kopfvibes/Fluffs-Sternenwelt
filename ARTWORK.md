# Grafiken und Audio

Die mitgelieferten Referenzen des Auftraggebers dienen als gestalterische Grundlage: der hellblaue Fluff und die Übersicht der zwölf Handyansichten. Die App verwendet daraus abgeleitete, transparente Fluff-Motive, ein aufbereitetes Logo, Avatare, glänzende Aufgabensymbole sowie eigene Tag- und Nachthintergründe.

Die Fluff-Motive enthalten Ruhepose, Winken, Blinzeln, Freude, Traurigkeit, Wut, Unsicherheit, Müdigkeit, Stolz, Entdecker, Schlafen, Sternfeier, Begrüßung mit Rucksack und Sitzen mit Kuscheltier. Der Begrüßungsarm wird über eine ClipPath-Ebene bewegt; die Bilddatei selbst bleibt unverändert. Die übrigen Animationen verwenden Bildwechsel und Flutter-Transformationen.

Die überarbeiteten Dateien `assets/art/fluff-celebrate-v2.png`, `icon-cinema-v2.png`, `icon-game-v2.png`, `icon-icecream-v2.png`, `icon-zoo-v2.png`, `day-world-v2.jpg` und `evening-world.jpg` wurden am 4. Oktober 2026 mit der eingebauten Bildgenerierung `image_gen.imagegen` aus den gelieferten Referenzen und vorhandenen Motiven erstellt. Die vollständigen Prompts stehen in `docs/artwork-prompts.json`. Die PNG-Dateien behalten ihre echte Transparenz; für die App wurden sie nur skaliert und mit einem transparenten Rand versehen. Die Hintergründe wurden als JPEG verkleinert. Die ursprünglichen Dateien bleiben enthalten.

Der dunkle Hintergrund der Sternfeier mit Lichtpunkten und animiertem Konfetti entsteht direkt in Flutter. Die Abendroutine verwendet die Bett-Szene mit Kissen aus `evening-world.jpg`.

`assets/fonts/OFL.txt` enthält die Lizenz für Nunito. Die statischen Schriftschnitte wurden aus der offiziellen Nunito-Schriftdatei erzeugt.

Die lokalen WAV-Dateien, Sternklänge und Musik stammen aus den wiedergefundenen Fluff-Projektpaketen. Die App spielt Stimme und Sternklang an passenden Aktionen ab. Die Musikdatei bleibt verfügbar, läuft aber nicht ungefragt als Hintergrundmusik.

Die Rechte an gelieferten Figuren, Marken und Audiodateien werden durch dieses Quellpaket nicht neu lizenziert. Vor einer öffentlichen Produktveröffentlichung liegt die Auswahl der freigegebenen Marken- und Mediendateien beim Projekteigentümer.
