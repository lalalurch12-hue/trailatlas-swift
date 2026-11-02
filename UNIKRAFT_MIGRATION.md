# Umzug auf Unikraft Cloud

Status: Auf Unikraft veröffentlicht; vollständige öffentliche Abnahme läuft. Neue HTTPS-Adresse: https://silent-water-yl7acse4.fra.unikraft.app/ . Der tatsächliche Swift-Server beantwortet `/health` mit HTTP 200. Die CLI-Freigabe für „Trail Atlas“ wurde nach ausdrücklicher Zustimmung des Benutzers erfolgreich abgeschlossen. Der kostenlose Hobby-Tarif ist im tatsächlichen Konto bestätigt. Die bestehende Render-Seite bleibt unter https://trailatlas-swift.onrender.com/ als Rückfallmöglichkeit erreichbar.

## Nachgewiesener Stand vom 2. November 2026

- Die angemeldete Organisation `trailatlas` zeigt im tatsächlichen Abrechnungsdialog „Hobby“ und „This plan is free.“; Kontingent: zwei vCPUs, 4096 MB Speicher, fünf Instanzen. Nachweis: `reports/unikraft-account-preflight.json`.
- Die offizielle Unikraft-CLI 0.6.2 ist mit Hersteller-Prüfsumme verifiziert. Der lokale Deployment-Probelauf (`--dry-run`) akzeptiert Frankfurt, 512 MiB RAM, eine vCPU und die HTTP-/HTTPS-Portzuordnung; er verwendet nur einen Image-Platzhalter und erstellt keine Instanz. Nachweis: `reports/unikraft-preparation.json`.
- GitHub-Actions-Lauf `41508962423` hat Commit `ee5045d2f5950bf40df6da087afda43701811ad1` vollständig als Swift-Release-Server gebaut (161,85 Sekunden Swift-Buildzeit). Das exportierte Linux-x86_64-Laufzeitdateisystem wurde heruntergeladen und anhand seiner SHA-256-Prüfsumme geprüft. Größe des komprimierten Archivs: 114.465.531 Bytes. Nachweis: `reports/unikraft-rootfs-build.json`.
- Die 352 ursprünglichen Rennen und die originale HTML-Designreferenz sind bytegleich erhalten. Der Swift-Anwendungsquellcode bleibt unverändert. Die reale Browserprüfung fand bei 360 Pixeln einen 13 Pixel breiten Überlauf der Kopfzeile; eine zusätzliche CSS-Regel verringert ausschließlich unterhalb von 381 Pixeln die Abstände. Desktopgestaltung, Beschriftungen und Funktionen bleiben erhalten. Das aktualisierte Laufzeitpaket wird vollständig neu gebaut. Das Image enthält keinen Sitzungsschlüssel.
- Die CI baut und exportiert ausschließlich das Docker-Laufzeitdateisystem. Unikraft-Zugangsdaten wurden nicht an GitHub übertragen. Die abschließende Unikraft-Paketierung und Veröffentlichung erfolgen nach der CLI-Freigabe mit dem lokalen Client.
- Das heruntergeladene Archiv liegt lokal bereit; das CI-Artefakt wird bis zum 5. November 2026, 19:23 UTC aufbewahrt. Der Build ist aus dem angegebenen Commit reproduzierbar.
- Die lokale CLI hat das vollständige Unikraft-OCI-Image gebaut und in die Registry `index.unikraft.io/trailatlas/trailatlas-swift:ee5045d` hochgeladen. Instanz `trailatlas-swift` in Frankfurt: 512 MiB RAM, eine vCPU, eine Replik, HTTPS und HTTP-Weiterleitung. Der stabile Sitzungsschlüssel wird ausschließlich zur Laufzeit gesetzt.
- Der persistente ext4-Datenträger `trailatlas-data` (128 MiB, innerhalb des im kostenlosen Konto angezeigten 1-GiB-Speicherkontingents) ist für `/data` vorgesehen; `DATA_DIR=/data/trailatlas`. Der Datenträger bleibt auch nach dem Löschen der Instanz erhalten. Die tatsächliche Wiederherstellung nach Neustart wird separat geprüft.

## Festgelegter Betriebsweg

- Der im tatsächlichen Konto bestätigte kostenlose Hobby-Tarif. Kein kostenpflichtiges Upgrade, keine zusätzlichen kostenpflichtigen Datenträger oder Dienste.
- Eine Instanz in Frankfurt (`fra`), zunächst 512 MiB RAM und eine vCPU. Öffentlich HTTPS 443 auf den Swift-Port 10000; HTTP 80 leitet auf HTTPS um.
- `Kraftfile` verwendet das bestehende Dockerfile, die generische Kompatibilitätslaufzeit und EROFS. Für die lokale Paketierung ohne Docker steht eine temporäre Kraftfile-Variante mit dem geprüften Tarball als Rootfs-Quelle bereit. Ein ausdrücklicher Wechsel nach `/app` erhält den relativen Zugriff auf `Resources`.
- Swift, Hummingbird, Elementary, die 352 ursprünglichen Rennen und die skriptfreie Oberfläche bleiben erhalten. Keine Änderungen am Anwendungs-Quellcode oder an den Originalressourcen für diese Vorbereitung.
- Tangled bleibt Hauptrepository; der öffentliche Datenbranch und seine laufenden Quellenprüfungen bleiben zuständig.
- `SESSION_SECRET` wird erst zur Laufzeit als Geheimnis gesetzt und weder in das Image noch in die Konfiguration geschrieben.

## Noch ausstehende Schritte

1. Die öffentliche HTTPS-Prüfung für alle Filter und 352 Rennkarten, Favoriten, Ergebnisansichten und Export abschließen.
2. Kalender, Raster, Live-Ergebnisse und mobile Filter bei 360, 390, 768 und 1280 Pixeln mit ausgeschaltetem Browser-JavaScript prüfen.
3. Tatsächliche Datenpersistenz und Favoriten nach einem Neustart prüfen, einschließlich eines Tests ohne die Wiederherstellungs-Cookies.
4. Quellenabruf von Tangled und echte Ergebnisabrufe durch die Unikraft-Instanz prüfen. Dateizugriff und Swift NIO sind durch den gestarteten Server und die öffentlichen APIs bereits bestätigt.
5. Den Benutzerkontext dokumentieren: Die Docker-Anweisung USER wird von der Kompatibilitätslaufzeit nicht automatisch als Laufzeitbenutzer übernommen. Die Anwendung läuft innerhalb einer isolierten Unikraft-MicroVM; die UID-Garantie des Docker-Images darf nicht als Nachweis für den Unikraft-Gast ausgegeben werden.
6. Domainwechsel dokumentieren: bestehende Cookies für `onrender.com` werden vom Browser nicht an die neue Domain gesendet. Alte Favoriten sind weiterhin auf der bisherigen Adresse erreichbar; eine automatische Übernahme in den Browser des Benutzers wurde nicht durchgeführt.
7. Erst nach bestandener Abnahme die neue Adresse als Hauptveröffentlichung bestätigen und den vollständigen Prüfbericht aktualisieren.

## Aktuelle Referenzen

- Tarif: https://unikraft.com/pricing
- Übernahme eines Docker-Images: https://unikraft.com/docs/tutorials/docker-to-ukc
- Kraftfile v0.7: https://unikraft.com/docs/kraftfile/v0.7
- CLI: https://unikraft.com/docs/cli/overview
- Bauen: https://unikraft.com/docs/cli/unikraft/build
- Starten: https://unikraft.com/docs/cli/unikraft/run
