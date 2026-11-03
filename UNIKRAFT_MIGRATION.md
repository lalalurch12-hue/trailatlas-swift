# Umzug auf Unikraft Cloud

Status: veröffentlicht und vollständig im beschriebenen Umfang geprüft. Öffentliche Website: https://silent-water-yl7acse4.fra.unikraft.app/ . Der vollständige Funktionsbericht steht in `PRUEFBERICHT.md`.

## Aktiver Betrieb

- Tatsächlich bestätigter kostenloser Hobby-Tarif der Organisation `trailatlas`; eine Instanz in Frankfurt (`fra`), eine vCPU und 512 MiB RAM. Kein kostenpflichtiges Upgrade oder Zusatzdienst.
- HTTP 80 leitet auf HTTPS um; HTTPS 443 führt zum Swift-Port 10000. Die aktuelle öffentliche Adresse und das TLS-Zertifikat wurden mit echten Internetabrufen geprüft.
- Persistenter ext4-Datenträger `trailatlas-data`, 128 MiB innerhalb des angezeigten 1-GiB-Kontingents. Unter `/data` eingehängt; `DATA_DIR=/data/trailatlas`. Der Datenträger ist unabhängig vom Lebenszyklus der Instanz.
- Stabiler Sitzungsschlüssel ausschließlich in der Laufzeitkonfiguration; kein Schlüssel im Image, im Repository, im Bericht oder in der GitHub-CI.
- Scale-to-Zero ist deaktiviert. Die Swift-Prüfung läuft bei aktiver Instanz im 96-Minuten-Takt über rotierende Teilmengen weiter. Die Tangled-Quellenprüfung läuft zusätzlich ungefähr alle zwei Stunden.
- Tangled bleibt das Hauptrepository. GitHub wurde als zusätzliche Build- und Prüfumgebung verwendet. Der bisherige kostenlose Render-Dienst bleibt unter https://trailatlas-swift.onrender.com/ als Rückfallmöglichkeit erreichbar.

## Nachgewiesene Abnahme

- Veröffentlichter Laufzeitquellstand: `416e14db47ceb3b7cf6be025e41e4414a080ab61`.
- Vollständiger Swift-Release-Build `41547877617` erfolgreich; Swift-Buildzeit 243.9 Sekunden. Runtime-Dateisystem und kompilierte Linux-x86_64-Anwendung anhand der SHA-256-Werte geprüft.
- Aktuelles Registry-Image: `trailatlas/trailatlas-swift@sha256:d6224e3c37121f765e4843e1f98444f753ffde4c4c800add9c2a0c7ea4fea73b`. `Kraftfile` verwendet die generische Kompatibilitätslaufzeit und EROFS; ein ausdrücklicher Wechsel nach `/app` erhält den Zugriff auf `Resources`. Die lokale Paketierung nutzte das in CI gebaute und geprüfte Tarball-Dateisystem.
- Alle 352 ursprünglichen Rennen und die originale HTML-Designreferenz bytegleich erhalten. Farben, Schriftgestaltung, Karten und Funktionen erhalten. Eine zusätzliche CSS-Regel korrigiert die Kopfzeilenabstände unterhalb von 381 Pixeln. Die Trackingmeldung unterscheidet jetzt einen fehlenden eindeutigen Treffer von einem Verbindungsfehler.
- `462` öffentliche HTTPS-Anfragen im erfolgreichen Lauf `41549501335`: alle Länder-, Monats-, Jahres-, Kategorie-, Distanz- und Suchfilter, Sortierungen, Ansichten, 352 Karten, 120 Quellenverweise, Favoriten, CSRF, Isolation, Export und echte UTMB-/WeRun-Abrufe.
- `16` Browserprüfungen im erfolgreichen Lauf `41549501161` bei 360, 390, 768 und 1280 Pixeln, jeweils mit ausgeschaltetem JavaScript. Kalender, Raster, Live-Bereich, mobiles Filtermenü, Formularsuche und geöffnete Details bestanden; kein horizontaler Seitenüberlauf.
- Tatsächliche Imagewechsel und Neustarts behielten Adresse, Datenträger und Favorit. Der erste Favoritenabruf nach Neustart verwendete nur den Sitzungs-Cookie, keine Wiederherstellungs-Cookies.

## Dokumentierte Grenzen

- Alte `onrender.com`-Cookies werden vom Browser nicht an die neue Domain gesendet. Eine automatische Übernahme aus dem Browser des Benutzers wurde nicht durchgeführt; die alte Adresse bleibt für vorhandene Favoriten erreichbar.
- Nicht jedes Rennen veröffentlicht zugängliche Live-Daten. Geschlossene Angebote, Loginpflichten und fremde JavaScript-/GPS-Widgets bleiben im Prüfbericht beschrieben eingeschränkt und werden gegebenenfalls extern verlinkt. Die rotierende Suche behauptet keine vollständige Abdeckung aller 352 Rennen in jedem Durchlauf.
- Die Docker-Anweisung USER wird von der Unikraft-Kompatibilitätslaufzeit nicht automatisch als Benutzeridentität im Gast übernommen. Die Anwendung läuft in einer isolierten MicroVM; eine UID-65534-Garantie wird für den Gast nicht behauptet. Kein kostenpflichtiger vollständiger Linux-VM-Tarif wurde aktiviert.

## Referenzen

- Tarif: https://unikraft.com/pricing
- Docker-Kompatibilitätslaufzeit: https://unikraft.com/docs/tutorials/docker-to-ukc
- Kraftfile: https://unikraft.com/docs/kraftfile/v0.7
- Persistente Datenträger: https://unikraft.com/docs/platform/volumes

Die maschinenlesbaren Ergebnisse liegen in `reports/unikraft-*.json` und `reports/public-https-unikraft-*.json`. Private Cookies, Anmeldelinks und Zugangsdaten bleiben außerhalb der ausgelieferten Dateien.
