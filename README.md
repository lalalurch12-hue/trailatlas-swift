# TrailAtlas · Swift ohne Browser-JavaScript

TrailAtlas verwendet Swift 6.2, Hummingbird und Elementary. Alle 352 ursprünglichen Renndatensätze bleiben erhalten. Die aktive Oberfläche nutzt HTML, das ursprüngliche CSS und serverseitige Formulare. Die Originaldatei in `Resources/original_unmodified.html` ist eine unveränderte Referenz und wird nicht als aktive Seite ausgeliefert.

## Aktueller Stand

Der vollständige Debug- und Release-Build wurde mit echten Paketabhängigkeiten ausgeführt. Filter, persönliche Speicherung und öffentliche Ergebnisquellen werden gegen den laufenden Hummingbird-Server geprüft. Der vollständige Bericht steht in `PRUEFBERICHT.md`.

**Veröffentlicht: https://silent-water-yl7acse4.fra.unikraft.app/**. Der Swift-Server läuft im bestätigten kostenlosen Unikraft-Hobby-Tarif in Frankfurt mit einer vCPU, 512 MiB RAM und 128 MiB dauerhaftem Speicher. Die vollständige öffentliche HTTPS-Abnahme, mobile Formulare mit ausgeschaltetem JavaScript und die Speicherung über einen tatsächlichen Imagewechsel hinweg sind geprüft. Details stehen in `PRUEFBERICHT.md` und `UNIKRAFT_MIGRATION.md`. Hauptrepository und wiederkehrende Quellenprüfungen: https://tangled.org/lalalurch.tngl.sh/trailatlas-swift . GitHub wurde als Build- und Prüfumgebung verwendet; Unikraft-Zugangsdaten bleiben außerhalb der CI. Die bisherige Render-Adresse https://trailatlas-swift.onrender.com/ bleibt als Rückfallmöglichkeit erhalten.

## Funktionen

- Suche, 65 Länder, Monate, Jahre, Kategorien, Distanzbereiche, Sortierung, Listen-/Kartenansicht und schrittweises Nachladen.
- Persönliche Favoriten, eigene Quellen und manuelle Trackinglinks ohne Benutzerkonto.
- Terminübernahme aus passenden strukturierten Veranstaltungsdaten und explizit erkannten Veranstalterangaben; mehrdeutige Hinweise bleiben zur Bestätigung stehen. Änderungen wirken auf Karten, Filter, Wochenenden und API.
- Datumsbereiche über Monatsgrenzen, deutsche/englische/chinesische Datumsformate und Schutz vor der Verwechslung von Anmeldung, Festivalzeitraum und Einzelrennen.
- Offizielle Quellenseiten, öffentliche WeRun-Verzeichnisse und ergänzende Suchindizes für Ergebnis- und Trackinglinks. Rennname und Jahresausgabe werden geprüft. Nicht jedes Rennen veröffentlicht eine frei zugängliche Quelle.
- Native HTML-Ergebnistabellen für UTMB Live über dessen öffentliche Datenschnittstelle. Öffentliche HTML-/JSON-Quellen weiterer Anbieter werden bei erkennbarer Struktur ebenfalls angezeigt. Teilnehmerlisten ohne gemessene Zeiten werden nicht als Live-Ergebnisse ausgegeben.
- HTML-Meta-Refresh beim Betrachten einer Ergebnisansicht; kein eigenes JavaScript und `script-src 'none'`. Fremde iframes sind ebenfalls ohne Skriptausführung eingebettet.
- Vollständiger HTML-Export als Momentaufnahme. Offline können keine Swift-Filter oder Serverprüfungen ausgeführt werden.

## Kostenloser Betrieb und Speicherung

Der aktive Unikraft-Hobby-Tarif wurde in der tatsächlichen Abrechnungskonsole als kostenlos bestätigt. Die Instanz bleibt mit einer vCPU und 512 MiB RAM innerhalb des kostenlosen Kontingents von zwei vCPUs und 4 GiB RAM. Der persistente ext4-Datenträger `trailatlas-data` belegt 128 MiB des angezeigten 1-GiB-Speicherkontingents. Es wurden keine kostenpflichtigen Dienste, Upgrades oder automatische kostenpflichtige Erweiterungen eingerichtet. `Dockerfile`, `Kraftfile` und `UNIKRAFT_MIGRATION.md` beschreiben den Betriebsweg; `render.yaml` bleibt für den bisherigen kostenlosen Render-Dienst erhalten.

Persönliche Daten liegen auf Unikraft zusätzlich dauerhaft unter `/data/trailatlas`. Ein tatsächlicher Imagewechsel mit Neustart erhielt den gespeicherten Favoriten bereits allein anhand der Sitzungskennung, ohne Wiederherstellungs-Cookies. Komprimierte, authentifiziert verschlüsselte HttpOnly-Cookies bleiben als zusätzliche Wiederherstellungsmöglichkeit bei vollständigem Verlust des Serverspeichers erhalten; dafür ist ein gleichbleibender `SESSION_SECRET` erforderlich. Die Zuordnung bleibt an den Browser gebunden; Cookie-Löschung entfernt diese Zuordnung. Es gibt keine Synchronisierung zwischen Geräten. Größenlimits werden ausdrücklich gemeldet. Cookies der alten Render-Domain werden nicht automatisch an die neue Domain übertragen.

Öffentliche Prüfergebnisse werden durch `.tangled/workflows/trailatlas.yml` regelmäßig im separaten Branch `trailatlas-data` gesichert. Der Swift-Dienst liest diesen über `SHARED_DATA_BASE_URL`. Personenbezogene Sessions, Favoriten und persönliche Quellen werden aus öffentlichen Exporten entfernt. Dieser Branch und der Zeitplan sind auf Tangled eingerichtet; ein echter geplanter Spindle-Lauf und erfolgreiche Git-Pushes sind nachgewiesen. Neue, nur auf einer Render-Instanz gefundene Links sind bis zur unabhängigen Sicherung durch den Tangled-Prüflauf lediglich lokal zwischengespeichert.

Die aktive Unikraft-Instanz ist ohne Scale-to-Zero eingerichtet; ihre regelmäßige Serverprüfung läuft während des Betriebs weiter. Die Render-Rückfallinstanz kann weiterhin schlafen und besitzt dort keinen dauerhaften lokalen Datenträger. Der eingerichtete Tangled-Zeitplan arbeitet davon unabhängig ungefähr alle zwei Stunden; Ausführungen können sich verzögern oder vom Anbieter ausgesetzt werden. Der Server prüft im 96-Minuten-Takt rotierende Teilmengen, nicht sämtliche 352 Rennen gleichzeitig. Fehlende eindeutige Suchtreffer werden von Verbindungsfehlern unterschieden.

## Konfiguration

| Variable | Zweck |
|---|---|
| `PORT` | HTTP-Port; Bindung an `0.0.0.0` |
| `DATA_DIR` | Auf Unikraft dauerhaft `/data/trailatlas`; auf Render Free flüchtig |
| `SESSION_SECRET` | Stabiler geheimer Schlüssel für persönliche Wiederherstellung und Formularschutz |
| `COOKIE_SECURE` | Für HTTPS auf `1` |
| `SHARED_DATA_BASE_URL` | Öffentlicher Datenbranch des eigenen Projekts |
| `DISABLE_BACKGROUND` | Isolierte Tests ohne periodische Netzabrufe |
| `PUBLIC_DATA_DIR` | Zielordner des eigenständigen Swift-Prüflaufs |

## Prüfungen

`Package.resolved` hält die tatsächlich aufgelösten Abhängigkeiten fest. Die CI-Konfiguration baut den vollständigen Release-Server und führt die Kernprüfungen sowie echte HTTP-Tests aus. Die lokale Testausführung, erfolgreiche Cloud-Läufe und die bestandene öffentliche Abnahme mit 462 HTTPS-Anfragen werden im Prüfbericht getrennt ausgewiesen.

`/health` ist ein schneller Bereitschaftscheck. `/api/races` enthält die wirksamen öffentlichen Kalenderdaten; `/api/status` meldet Prüfstände und Konfiguration ohne persönliche Daten oder Geheimnisse.
