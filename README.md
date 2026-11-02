# TrailAtlas · Swift ohne Browser-JavaScript

TrailAtlas verwendet Swift 6.2, Hummingbird und Elementary. Alle 352 ursprünglichen Renndatensätze bleiben erhalten. Die aktive Oberfläche nutzt HTML, das ursprüngliche CSS und serverseitige Formulare. Die Originaldatei in `Resources/original_unmodified.html` ist eine unveränderte Referenz und wird nicht als aktive Seite ausgeliefert.

## Aktueller Stand

Der vollständige Debug- und Release-Build wurde mit echten Paketabhängigkeiten ausgeführt. Filter, persönliche Speicherung und öffentliche Ergebnisquellen werden gegen den laufenden Hummingbird-Server geprüft. Der vollständige Bericht steht in `PRUEFBERICHT.md`.

**Die Veröffentlichung auf Render ist noch nicht erfolgt.** Es werden weder eine öffentliche URL noch aktivierte GitHub-Zeitpläne behauptet. Die kontobezogenen Voraussetzungen stehen in `DEPLOY_STATUS.md`.

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

`Dockerfile` und `render.yaml` beschreiben einen Render-Webdienst mit dem Plan `free`. Es werden keine kostenpflichtigen Datenbanken, Datenträger oder Render-Cronjobs angelegt.

Persönliche Daten werden als komprimierte, authentifiziert verschlüsselte, HttpOnly-Cookies gespeichert. Bei gleichbleibendem `SESSION_SECRET` bleiben sie nach einem vollständigen Verlust des lokalen Serverspeichers erhalten. Sie sind an den Browser gebunden; Cookie-Löschung oder ein Wechsel des Schlüssels entfernt diese Wiederherstellungsmöglichkeit. Es gibt keine Synchronisierung zwischen Geräten. Größenlimits werden ausdrücklich gemeldet.

Öffentliche Prüfergebnisse können durch `.github/workflows/refresh.yml` regelmäßig in einem separaten Branch `trailatlas-data` gesichert werden. Der Swift-Dienst liest diesen über `SHARED_DATA_BASE_URL`. Personenbezogene Sessions, Favoriten und persönliche Quellen werden aus öffentlichen Exporten entfernt. Die Einrichtung dieses Branches und die Aktivierung des Zeitplans sind Bestandteil der noch ausstehenden Veröffentlichung. Neue, nur auf einer Render-Instanz gefundene Links sind bis zur unabhängigen Sicherung durch den GitHub-Prüflauf lediglich lokal zwischengespeichert.

Render Free kann schlafen und besitzt keinen dauerhaften lokalen Datenträger. Die Serverprüfung läuft deshalb nur bei aktiver Instanz. Der vorbereitete GitHub-Zeitplan arbeitet davon unabhängig ungefähr alle zwei Stunden; Ausführungen können sich verzögern oder vom Anbieter ausgesetzt werden. Der Server prüft im 96-Minuten-Takt rotierende Teilmengen, nicht sämtliche 352 Rennen gleichzeitig.

## Konfiguration

| Variable | Zweck |
|---|---|
| `PORT` | HTTP-Port; Bindung an `0.0.0.0` |
| `DATA_DIR` | Lokaler Cache, auf Render Free flüchtig |
| `SESSION_SECRET` | Stabiler geheimer Schlüssel für persönliche Wiederherstellung und Formularschutz |
| `COOKIE_SECURE` | Für HTTPS auf `1` |
| `SHARED_DATA_BASE_URL` | Öffentlicher Datenbranch des eigenen Projekts |
| `DISABLE_BACKGROUND` | Isolierte Tests ohne periodische Netzabrufe |
| `PUBLIC_DATA_DIR` | Zielordner des eigenständigen Swift-Prüflaufs |

## Prüfungen

`Package.resolved` hält die tatsächlich aufgelösten Abhängigkeiten fest. Die CI-Konfiguration baut den vollständigen Release-Server und führt die Kernprüfungen sowie echte HTTP-Tests aus. Die lokale Testausführung und der zukünftige GitHub-Actions-Lauf werden im Prüfbericht getrennt ausgewiesen.

`/health` ist ein schneller Bereitschaftscheck. `/api/races` enthält die wirksamen öffentlichen Kalenderdaten; `/api/status` meldet Prüfstände und Konfiguration ohne persönliche Daten oder Geheimnisse.
