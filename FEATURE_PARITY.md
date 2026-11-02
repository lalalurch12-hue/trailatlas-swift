# Funktionsabgleich

| Funktion | Umsetzung | Grenze |
|---|---|---|
| Originaldesign und 352 Rennen | Originalreferenz unverändert, ursprüngliches CSS erhalten, Swift rendert die Oberfläche | Ergänzungen für Formulare und Ergebnisse verwenden die bestehende Gestaltung |
| Suche, Länder, Zeiträume, Distanzen | Serverseitige GET-Filter | Eingaben werden per Enter oder Formularschaltfläche bestätigt |
| Elite, Serien, TBA und Favoritenfilter | Korrekte Checkboxwerte und kombinierbare Filter | Angaben zu Elitefeldern stammen aus der ursprünglichen Sammlung |
| Liste, Karten, Sortierung, Nachladen | Swift-Rendering und normale Links | Neuladen der Seite ersetzt DOM-Änderungen |
| Favoriten und eigene Quellen | Verschlüsselte persönliche Cookies und lokaler Cache | Browsergebunden, keine Konten oder geräteübergreifende Synchronisierung |
| Automatische Terminübernahme | Strukturierte Events, erkannte Veranstalterangaben, klare Zuordnung zur Ausgabe | Unklare Angaben, Anmeldung und mehrdeutige Einzelrennen werden nicht blind übernommen |
| Neue bestätigte Ausgaben | Zusätzliche Einträge aus eindeutig zugeordneten Quellen | Die 352 Originaldatensätze werden dabei nicht gelöscht |
| Eigene Quellenseiten | Öffentliche HTTPS-Adressen, DNS-/IP-Prüfung, kontrollierte Abrufe, persönliche Hinweise | Eigene Hinweise erfordern Bestätigung; private Netzadressen werden nicht abgerufen |
| Wiederholte Quellenprüfung | Rotierende Teilmengen auf dem Server; separater Tangled-Prüflauf aktiv | Kein Garantietakt während Ausfällen oder Schlafzeiten; Cloud-Läufe erfolgreich; keine Ausführungsgarantie |
| Automatische internationale Tracking-Suche | Veranstalterlinks, zugelassene Zeitmessdienste und öffentliche Suchindizes | Suchdienste können irrelevante Treffer liefern oder Zugriffe blockieren |
| Chinesische Quellen | WeRun-Verzeichnis, chinesische Suchbegriffe und Namenszuordnungen, weitere Anbieter-Domains | Keine geschlossenen WeChat-/App-Inhalte; eine gefundene Quelle bedeutet noch keine veröffentlichten Zeiten |
| Live-Ergebnisse direkt in TrailAtlas | UTMB-API, passende öffentliche HTML-/JSON-Tabellen | UTMB maximal 30 Einträge je Strecke; generische Tabellen maximal 100; keine erfundenen Resultate |
| Regelmäßige Ergebnisaktualisierung | Cache und HTML-Meta-Refresh etwa alle 90 Sekunden | Gesamte Seite wird neu geladen; Anbieter können Daten verzögern |
| RACE RESULT und andere JS-Widgets | Öffentliche Daten werden nach Möglichkeit serverseitig gelesen; Originalquelle bleibt verlinkt | JavaScript-Widgets und interaktive GPS-Karten sind ohne Browser-JavaScript nicht identisch reproduzierbar |
| iframe-Fallback | Skriptfreie, eingeschränkte Einbettung | CSP, X-Frame-Options und JS-Pflicht beim Anbieter können die Anzeige verhindern |
| Bild-Momentaufnahmen | Vorhandener optionaler Mechanismus bleibt im Quelltext | Standardmäßig aus; ausgeliefertes Render-Image enthält kein Chromium |
| Prüflauf stoppen | Eigener gestarteter Lauf kann gestoppt werden | Öffentliche Besucher stoppen keine fremden oder geplanten Prüfungen |
| HTML exportieren | Alle Kalenderkarten als HTML-Momentaufnahme | Serverfunktionen sind offline nicht ausführbar |
| Öffentliches HTTPS | Kostenloser Render-Dienst veröffentlicht | Kaltstart und Schlafzeiten im Free-Plan; Render benötigt einen dokumentierten GitHub-Buildadapter |
| Dauerhafte gemeinsame Daten | Tangled-Datenbranch und Abruf auf Render aktiv | Nur auf einer Serverinstanz neue Funde sind bis zum unabhängigen Cloud-Lauf lokal |
