# TrailAtlas – Funktions- und Veröffentlichungsprüfung

Stand: 2. November 2026. Öffentliche Website: https://trailatlas-swift.onrender.com/ . Angaben zu Prüfläufen verwenden UTC-Zeitstempel; der Nutzer befindet sich in Europe/Berlin.

## Ergebnis

TrailAtlas ist als Swift-/Hummingbird-/Elementary-Dienst auf Render veröffentlicht: **https://trailatlas-swift.onrender.com/**. Das verwendete Laufzeitpaket wurde mit Swift 6.2.4 vollständig gebaut; zuvor bestanden auch lokale Builds mit Swift 6.2.1. Die 352 Originalrennen, die Originalreferenz und das ursprüngliche CSS sind erhalten. Die aktive Oberfläche enthält kein Browser-JavaScript.

Der kostenlose Render-Webdienst, ein stabiler Sitzungsschlüssel und die externe Sicherung gemeinsamer Daten sind eingerichtet. GitHub-Build, HTTP-Regressionen, alle 352 Detailkarten und der geplante Quellenlauf sind erfolgreich ausgeführt worden. Die abschließende öffentliche HTTPS-Abnahme ist unten gesondert dokumentiert. Es wurden keine kostenpflichtigen Dienste eingerichtet.

Der gewünschte Wechsel von GitHub zu Tangled ist noch nicht vollzogen: Tangled konnte den im sicheren Anmeldefeld eingegebenen Handle nicht auflösen. GitHub bleibt bis zu einer erfolgreichen Übernahme die bestehende Quelle. Das ist keine technische Bindung von Swift oder Render an GitHub; die Workflows, die öffentliche Abrufadresse und deren Freigabe in der Swift-Konfiguration müssen beim Wechsel angepasst werden.

## Anforderungen und Nachweis

| Anforderung | Ergebnis | Nachweis / verbleibende Grenze |
|---|---|---|
| Swift, Hummingbird und Elementary beibehalten | Bestanden | Vollständige Paketauflösung sowie Debug- und Release-Build; keine Ersatzimplementierung in einer anderen Serversprache |
| 352 Rennen vollständig erhalten | Bestanden | `races.json` bytegleich zum Eingangspaket; 352 eindeutige IDs; alle 352 Detailkarten per HTTP geöffnet |
| Originaldesign erhalten | Bestanden im geprüften Umfang | Original-HTML bytegleich; ursprüngliches CSS als unveränderter Präfix erhalten; Browserprüfung von Desktop, Raster und Mobilansichten; zusätzliche Regeln nur für serverseitige Bedienung und Ergebnisdarstellung |
| Browser ohne JavaScript | Bestanden | Keine Skripte oder Ereignishandler im aktiven HTML; Content-Security-Policy mit `script-src 'none'`; Formulare, Links und CSS bedienen die Oberfläche |
| Automatische Terminübernahme | Bestanden für eindeutige Quellen | Zuerst sechs, im gesicherten Cloud-Stand acht Terminübernahmen; Datumsänderungen wirken auf Karten, Filter, Reihenfolge, Wochenenden und öffentliche API |
| Internationale und chinesische Tracking-/Ergebnissuche | Implementiert und teilweise live nachgewiesen | Veranstalterlinks, Providerzuordnung, Jahresprüfung, WeRun-Verzeichnis und ergänzender Suchindex; Yangxian-Quelle tatsächlich automatisch gefunden. Keine vollständige Abdeckung aller 352 Rennen behauptet |
| Live-Ergebnisse innerhalb der Website | Bestanden für abrufbare Daten | Tatsächliche UTMB-Live-API-Daten als native HTML-Tabellen; öffentliche HTML-/JSON-Tabellen weiterer Quellen nach Strukturerkennung; eingeschränkter iframe-Fallback und Originalverweis |
| Regelmäßige Aktualisierung der Ergebnisse | Implementiert und öffentlich geprüft | Ergebnis-Cache etwa 80 Sekunden; HTML-Meta-Refresh etwa alle 90 Sekunden. Keine Garantie für die Aktualität der Daten beim Anbieter |
| Termin- und Trackingquellen erneut prüfen | Aktiv | Server prüft bei Fälligkeit und im 96-Minuten-Takt Teilmengen; GitHub-Zeitplan ungefähr alle zwei Stunden eingerichtet, tatsächliche Cloud-Läufe erfolgreich |
| Dauerhafte Favoriten und persönliche Quellen | Bestanden unter dokumentierten Voraussetzungen | Verschlüsselte Cookies; Neustart und vollständige Löschung des lokalen Servercaches getestet. Stabiler Sitzungsschlüssel und erhaltener Browser-Cookie erforderlich |
| Dauerhafte gemeinsame Daten und gefundene Quellen | Eingerichtet und getestet | GitHub-Datenbranch `trailatlas-data` mit tatsächlichen Sicherungen; erneuter Abruf durch den Render-Server. Neue reine Serverfunde bleiben bis zum unabhängigen Quellenlauf lokal |
| Alle Filter, Links, Rennkarten und Mobilansichten testen | Bestanden im beschriebenen Umfang | Alle 65 Ländergruppen, zwölf Monate, Jahre, Kategorien und Distanzfilter; alle 352 Karten; 120 Originalquellen tatsächlich abgerufen; Desktop und drei mobile Breiten geprüft |
| Vollständigen Swift-Build durchführen | Bestanden | Swift 6.2.4 in GitHub und Docker; reale Abhängigkeiten und vollständiger Release-Build erfolgreich |
| Veröffentlichung auf Render und echte HTTPS-Abnahme | Veröffentlicht | Kostenloser Docker-Webdienst in Frankfurt im Zustand live; öffentliche Prüfungen separat protokolliert |

## Durchgeführte Reparaturen

- Formularaktionen verwenden POST, CSRF-Schutz und anschließende Weiterleitung. Ein einfacher GET-Aufruf verändert keine Favoriten oder persönlichen Quellen. Doppelte HTML-Attribute und verschachtelte Formulare wurden entfernt.
- Checkboxen liefern korrekte Werte. Kombinierte Länder-, Such-, Monats-, Jahres-, Distanz-, Elite-, Serien-, TBA-, Favoriten- und Zukunftsfilter funktionieren. A–Z-Sortierung wird nicht durch Monatsgruppen unterbrochen; unbekannte Termine stehen bei Datumssortierung am Ende.
- Die Distanzanalyse erkennt auch deutsche Meilenangaben, gemeinsam verwendete Einheiten wie „10 / 30 / 50 km“, Halbmarathon/Marathon und lange Ultras. Höhenmeter werden nicht als Laufdistanz gewertet.
- Mehrtägige laufende Rennen werden in Zukunfts- und Wochenendansichten berücksichtigt. Details und Ergebnisbereiche sind auch im Kartenraster sichtbar und wieder schließbar.
- Die mobile Filterleiste öffnet und schließt über CSS-Anker. Ihre Abdeckung bleibt auf dem Desktop verborgen und verschiebt den Kalender nicht.
- HTML-Vorlage und Formularlinks werden in einem Durchlauf ausgegeben. Datum und Distanzfilter werden nur bei Bedarf neu berechnet. Umfangreiche Radarlisten entstehen beim Öffnen des Radars; Kalender und Karten behalten ihre unveränderte sichtbare Gestaltung. Blockierende Netzabrufe belegen keine Swift-Kooperationsthreads.
- Terminextraktion unterstützt strukturierte Veranstaltungsdaten, mehrere europäische Datumsformen, chinesische Jahres-/Monats-/Tagesangaben und Datumsbereiche über Monatsgrenzen. Anmeldungs-, Veröffentlichungs- und Lotteriedaten werden nicht blind übernommen.
- Ein Festivalzeitraum ersetzt nicht automatisch den abweichenden Termin eines Einzelrennens. Die Lavaredo-120K-Karte behält deshalb ihren eigenen Starttermin statt des Beginns der Veranstaltungswoche.
- Bestätigte spätere Ausgaben können als zusätzliche Karten erscheinen. Alle 352 Originaleinträge bleiben dabei vorhanden. Persönliche manuelle Bestätigungen wirken nur im betreffenden Browserprofil.
- Trackinglinks werden auf Rennen, Anbieter und Jahresausgabe geprüft. Vorübergehende Fehler wie 403/429 löschen eine Quelle nicht vorschnell. Wiederholte 404/410 und veraltete Ausgaben werden erkannt; die Suche berücksichtigt auch länger nicht geprüfte Rennen.
- Ergebnisdaten werden serverseitig abgerufen und HTML-sicher ausgegeben. Teilnehmer-/Startlisten ohne gemessene Zeiten werden nicht als Live-Platzierungen dargestellt. Bei vorübergehendem Abruffehler kann der letzte erfolgreiche Stand mit sichtbarem Zeitstempel erhalten bleiben.
- Eigene Quellenseiten, Hinweise, Favoriten und manuelle Trackinglinks sind zwischen Besuchern getrennt. Persönliche Daten werden aus öffentlichen Exporten entfernt. Abrufe eigener Quellen werden auf öffentliche HTTPS-Ziele begrenzt; private Netzadressen, unerlaubte Weiterleitungen und übergroße Antworten werden abgefangen.

## Reale Internetabrufe

Der erste vollständige Swift-Prüflauf kontrollierte zwölf Quellenseiten und exportierte sechs eindeutige Terminbereiche. Die späteren Cloud-Läufe setzten den Cursor fort; ein nachweislich gesicherter Stand enthält acht Terminübernahmen, fünf bekannte Trackingquellen und **keine persönlichen Sessions**. Das bedeutet keine komplette Aktualitätsprüfung sämtlicher Kalendereinträge in einem Durchlauf.

| Veranstaltung / Ausgabe | Erkannter Zeitraum | Art des Nachweises |
|---|---|---|
| Bandera Endurance Trail Race 2026 | 10.–11. Januar 2026 | Passende strukturierte Eventdaten der hinterlegten öffentlichen Quelle |
| HURT 100 2026 | 17.–18. Januar 2026 | Passende strukturierte Eventdaten der hinterlegten öffentlichen Quelle |
| Innsbruck Alpine Trailrun Festival 2027 | 5.–8. Mai 2027 | Eindeutige Veranstalterangabe |
| Großglockner Mountain Run 2027 | 2.–4. Juli 2027 | Eindeutiger Veranstaltungszeitraum des Veranstalters |
| Großglockner Ultra-Trail 2027 | 22.–25. Juli 2027 | Eindeutige Veranstalterangabe |
| Oberaudorf Trail Festival 2027 | 30. September–3. Oktober 2027 | Eindeutige Veranstalterangabe über Monatsgrenze |

Die öffentliche UTMB-Live-Schnittstelle lieferte echte Daten zur Ausgabe Kullamannen 2026. Die Anwendung zeigte daraus Platzierungen, Namen und Zeiten als eigene HTML-Tabelle an. Der Test verwendete keine erfundenen Beispielergebnisse.

Die chinesische Yangxian-Quelle wurde über das öffentliche WeRun-Verzeichnis automatisch gefunden und aufgerufen. Für die bevorstehende Ausgabe waren zum Prüfzeitpunkt noch keine gemessenen Ergebnisse veröffentlicht. Die Anwendung zeigt deshalb den Quellenhinweis und behauptet keine vorhandenen Live-Zeiten. Weitere unterstützte Domains und chinesische Namenszuordnungen verbessern die Suche, ersetzen jedoch keine Freigabe durch den jeweiligen Anbieter.

Alle **120 vorhandenen Original-Quellenlinks** wurden tatsächlich abgerufen:

| Abrufstatus | Anzahl | Bewertung |
|---|---:|---|
| HTTP 200 | 105 | Erreichbar zum Prüfzeitpunkt; ein erfolgreicher Status bestätigt nicht automatisch jede Datumsangabe |
| HTTP 503 | 14 | UTMB-Indexseiten antworteten mit einem Serverfehler; Links erhalten, nicht als gelöscht eingestuft |
| HTTP 403 | 1 | Webscorer verweigerte den automatisierten Abruf; Originalverweis erhalten |

Die automatische Terminüberwachung umfasst insgesamt 123 konfigurierte öffentliche HTTPS-Quellen nach Zusammenführung und Deduplizierung. Nicht jede der 352 Karten besitzt eine geeignete eigene Quellenseite. Ein ursprünglich hinterlegter HTTP-Link bleibt erhalten, wird aber nicht als ungesicherte automatische Abrufquelle verwendet.

## Build- und Funktionsprüfungen

| Prüfung | Ergebnis |
|---|---|
| Originaldaten und Originalreferenz gegen Eingangs-ZIP vergleichen | Bytegleich, SHA-256 im Evidenzordner |
| Vollständiger Swift-Debug-Build mit realen Abhängigkeiten | Lokaler früherer Stand erfolgreich; der abschließende Quellstand ist durch den vollständigen Release-Build geprüft |
| Vollständiger Swift-Release-Build mit realen Abhängigkeiten | Erfolgreich |
| Kernregressionen, Datumsanalyse, Kalenderübernahme, Quellenmigration | Erfolgreich |
| Schutz persönlicher Quellendaten und Ausschluss aus öffentlichem Export | Erfolgreich |
| Echter laufender Hummingbird-Server: Healthcheck und Kalender-API | Erfolgreich |
| Alle 65 Länderpartitionen; Summe 352 | Erfolgreich |
| Alle zwölf Monate, Jahreswahl, Kategorien, Distanzen, Suche und Sortierung | Erfolgreich |
| Listen-/Kartenansicht, Nachladen, Wochenende, Radar und HTML-Export | Erfolgreich |
| Alle 352 einzelnen Rennkarten und ihre 120 hinterlegten Quellenverweise | Erfolgreich |
| POST/Redirect, ungültiger CSRF-Code, sichere GETs und Besuchertrennung | Erfolgreich |
| Favoriten, eigene Quellen und manuelle Links nach Neustart und vollständigem Cacheverlust | Erfolgreich |
| Aktive Seiten ohne Skripte, Ereignishandler, doppelte Attribute und offene Platzhalter | Erfolgreich |
| Echte UTMB-Daten und echte WeRun-Quelle | Erfolgreich im beschriebenen Umfang |
| Blueprint gegen aktuelles offizielles Render-JSON-Schema | Erfolgreich |
| Tatsächlicher Docker-Image-Build / Render-Deploy | Erfolgreich; Dienst live |
| GitHub-Actions-Lauf und öffentlicher Datenbranch | Erfolgreich ausgeführt; Datenbranch enthält ausschließlich öffentliche Daten |
| Öffentliche HTTPS-Seite nach Render-Veröffentlichung | Siehe abschließendes öffentliches Prüfprotokoll |

Hummingbird wurde in Version 2.28.1 und Elementary in Version 0.8.4 aufgelöst; die vollständigen Abhängigkeiten sind durch `Package.resolved` festgehalten. Die Swift-Kernprüfungen verwenden für die isolierte Ausführung einen kleinen Elementary-Testersatz; die vollständigen Paket-Builds und HTTP-Prüfungen verwenden die tatsächlichen Bibliotheken. Es wird kein isolierter Test als Ersatz für den realen Serverbuild ausgegeben.

Die Browser-Sichtprüfung verwendete statische Momentaufnahmen des vom tatsächlichen Swift-Server erzeugten HTML. Die Interaktionen und Speicherung wurden zusätzlich über echte HTTP-Anfragen am Swift-Server geprüft. Zusätzlich wurde die echte Render-Adresse im Browser geöffnet: Länderfilter, Rasteransicht und geöffnete Details funktionierten; die Desktop-Seite zeigte keinen horizontalen Überlauf und kein Skriptelement.

Bei nominal 360, 390 und 768 Pixel breiten mobilen Ansichten waren Seitenbreite und Inhaltsscrollbreite jeweils gleich; es gab keinen horizontalen Seitenüberlauf. Das Filtermenü ließ sich bei 360 Pixeln öffnen und per Schließen-Link beziehungsweise Tastatur wieder schließen. Desktop- und Rasterdarstellung wurden zusätzlich kontrolliert. Dies ersetzt keine Prüfung auf jedem existierenden Mobilgerät.

## Speicherung und regelmäßiger Betrieb

Persönliche Daten liegen als komprimierte, authentifiziert verschlüsselte HttpOnly-Cookies vor; serverseitige Daten dienen als zusätzlicher Cache. Wiederherstellung nach Cacheverlust wurde mit gleichbleibendem Sitzungsschlüssel getestet. Auf Render wurde ein stabiler geheimer Sitzungsschlüssel gesetzt. Cookies werden für HTTPS als `Secure` ausgeliefert und besitzen eine begrenzte Laufzeit.

Diese Lösung bleibt an den jeweiligen Browser gebunden. Cookie-Löschung, Ablauf oder ein Wechsel des Sitzungsschlüssels verhindert die Wiederherstellung. Eine geräteübergreifende Benutzerkonten-Synchronisierung wurde nicht hinzugefügt. Bei Erreichen des Cookie-Größenlimits meldet die Anwendung den Fehler ausdrücklich, statt Favoriten stillschweigend zu verwerfen.

Gemeinsame Termin- und Trackingdaten werden durch den eingerichteten GitHub-Workflow in `trailatlas-data` dauerhaft versioniert. Die Website liest öffentliche Momentaufnahmen daraus ein. Sessions, persönliche Quellen und Favoriten werden nicht in diesen Branch veröffentlicht. Dieser Betriebsweg wurde mit dem echten Repository aktiviert; mehrere erfolgreiche Cloud-Läufe haben öffentliche Daten geschrieben, und der Render-Server hat sie eingelesen. Insbesondere schreibt eine kostenlose Render-Instanz neue Funde nicht sofort selbst in GitHub zurück; bis zum unabhängigen Prüflauf sind solche Funde nur lokal vorhanden.

Der Render-Plan `free` besitzt keinen dauerhaften lokalen Datenträger und kann bei Inaktivität schlafen. Währenddessen läuft seine periodische Swift-Prüfung nicht. Der eingerichtete GitHub-Zeitplan arbeitet davon unabhängig; GitHub kann geplante Ausführungen verzögern oder aussetzen. Im Serverlauf werden pro Runde Teilmengen kontrolliert, nicht alle Rennen im 96-Minuten-Abstand. Ein vollständiger Quelldurchlauf dauert entsprechend länger.

## Unvermeidbare und offene Einschränkungen

1. Eine skriptfreie Website kann fremde JavaScript-Widgets, geschlossene Apps und interaktive GPS-Karten nicht unverändert wiedergeben. Wo öffentliche Daten zugänglich sind, zeigt TrailAtlas native Tabellen. Sonst bleibt ein Verweis auf die Originalquelle. CSP, X-Frame-Options und Loginpflicht können auch eine skriptfreie Einbettung verhindern.
2. Kein Suchindex deckt alle internationalen und chinesischen Rennen zuverlässig ab. Offizielle Seiten können Datumsangaben oder Ergebnisse erst kurz vor dem Rennen veröffentlichen. Der getestete ergänzende Suchindex lieferte teilweise irrelevante Treffer; die strenge Renn-/Jahresprüfung verwirft diese.
3. Ergebnislisten werden begrenzt dargestellt: UTMB bis zu 30 Einträge je Strecke und maximal acht Strecken je Abruf; generische Tabellen bis zu 100 Zeilen. Es wird keine vollständige Reproduktion sämtlicher Anbieterfunktionen zugesichert.
4. Der vorhandene optionale Mechanismus für Ergebnis-Bildaufnahmen bleibt im Quelltext erhalten, ist standardmäßig deaktiviert und benötigt zusätzliche Laufzeitsoftware. Das vorbereitete Render-Image enthält kein Chromium. Es wird kein kostenpflichtiger Screenshotdienst verwendet.
5. Der HTML-Export enthält sämtliche Kalenderkarten als Momentaufnahme. Offline sind die Swift-Filter, persönlichen Aktionen und Netzprüfungen nicht ausführbar.
6. Der Stopp-Knopf beendet einen eigenen gestarteten Prüflauf; öffentliche Besucher können keine fremden oder geplanten Läufe beenden. Das Entfernen einer persönlichen Trackingvorgabe löscht keine gemeinsam verifizierte Anbieterquelle.
7. Render verwendet derzeit eine öffentliche Git-Adresse ohne integrierte Git-Provider-Anmeldung. Codeänderungen benötigen daher einen gezielten Deploy. Laufende Quellenaktualisierungen nutzen den separaten Datenbranch und benötigen keinen Code-Deploy.
8. Eine vollständige Umstellung auf Tangled ist vor erfolgreicher Kontoanmeldung, Repository-Import, Spindle-Prüflauf und Umstellung der Datenadresse nicht als erledigt bestätigt.

## Veröffentlichung und Konten

Der Benutzer hat den Render-Workspace bestätigt. Das GitHub-Repository `lalalurch12-hue/trailatlas-swift` und der kostenlose Render-Webdienst `trailatlas-swift` wurden eingerichtet. Persönliche Testcookies und Produktionsschlüssel sind nicht Teil des Repositorys.

Der erste GitHub-Quellenlauf scheiterte an der Eigentümerprüfung des Container-Arbeitsverzeichnisses. Die Korrektur vertraut ausschließlich dem eigenen Checkout und seinem Daten-Arbeitsverzeichnis. Anschließende vollständige Cloud-Läufe waren erfolgreich und schrieben den Datenbranch.

Die Tangled-Anmeldung steht beim Fehler „Unable to look up that handle“. Es wurden keine Zugangsdaten im Chat angefordert und keine bestehenden Daten entfernt. Die Übernahme kann mit einem gültigen Tangled-/Bluesky-Handle weitergehen.

## Abschließende öffentliche Abnahme

Die vollständige Abnahme gegen **https://trailatlas-swift.onrender.com/** bestand am **2. November 2026 um 13:59:49 UTC** mit **462 HTTPS-Anfragen**. Der maschinenlesbare Bericht steht in `reports/public-https-final.json`; er enthält keine persönlichen Cookies.

| Öffentlich geprüfter Bereich | Ergebnis |
|---|---|
| HTTPS, `/health`, öffentliche APIs und unveränderte 352 Original-IDs | Bestanden |
| 65 Länder, zwölf Monate, Jahre, Kategorien, Distanzen, Suche, Sortierungen und Ansichten | Bestanden |
| Alle 352 Detailkarten und ihre 120 ursprünglichen Quellenverweise | Bestanden; die Erreichbarkeit der externen Zielseiten wurde zusätzlich separat wie oben beschrieben geprüft |
| Favorit per POST mit Weiterleitung, sichere GETs, CSRF-Abweisung und Besuchertrennung | Bestanden; Cookies `Secure` und `HttpOnly` |
| Vollständiger HTML-Export, HTML-Escaping und skriptfreie geprüfte Seiten | Bestanden |
| Reale UTMB-Schnittstelle vom Render-Server abgerufen und chinesische WeRun-Quelle angezeigt | Bestanden; für Yangxian weiterhin keine erfundenen gemessenen Zeiten |
| Bereits gespeicherter Favorit nach tatsächlichem Render-Neustart/Deploy | Bestanden, gesonderter öffentlicher Nachtest um 13:50:05 UTC; `reports/render-cookie-recovery.json` |

Der erfolgreiche öffentliche GitHub-Prüflauf ist [41456672999](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41456672999). Der vollständige Swift-Build einschließlich Kern-, HTTP- und Kartenprüfungen desselben Quellstands ist [41456672847](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41456672847) und ebenfalls erfolgreich. Geplante Quellenprüfung und tatsächliche Sicherung sind zusätzlich durch [41453335356](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41453335356) nachgewiesen. Zeitpläne können vom Anbieter verzögert werden.

Der aktive Render-Deploy `dep-dbk991mtlv9c73f7qnh0` ist seit 13:48:15 UTC im Zustand `live` und verwendet Commit `07755cd5bafb5248d9f04fa688492b3d449a3d8b`. Der abschließend geprüfte Commit `8d40b0666c11928946df92d26fa8b377d74ad4de` änderte danach ausschließlich den Namen des CI-Berichtsartefakts. Der Swift-Laufzeitcode ist gegenüber dem erfolgreich gebauten und veröffentlichten Stand `fa3189b6ee30dee1f9c329509143ac6a70d41fe6` unverändert. Spätere reine Berichtsänderungen benötigen keinen weiteren Deploy.

Ein früherer öffentlicher Gesamtlauf war mit dem absichtlich ausgelösten Render-Neustart überlappt und erhielt dabei einen einzelnen HTTP 502. Dieser Lauf wird ausdrücklich nicht als bestanden gezählt. Der oben angegebene Wiederholungslauf erfolgte nach abgeschlossenem Deploy und bestand vollständig. Kurze Unterbrechungen beim Deploy und Kaltstarts bleiben beim gewählten kostenlosen Betriebsweg möglich.

## Beiliegende Evidenz

Der Ordner `reports` enthält maschinenlesbare Ergebnisse der HTTP- und Kartenprüfungen, den erfolgreichen Kernprüflauf, den erfolgreichen Release-Build, den tatsächlichen öffentlichen Quellenprüflauf, die 120 einzelnen Linkabrufe, die Schema-Validierung, Datenintegritätswerte und Browsermessungen. Persönliche Testcookies, Sitzungsschlüssel, SDKs und Build-Caches sind nicht Bestandteil des Auslieferungspakets.
