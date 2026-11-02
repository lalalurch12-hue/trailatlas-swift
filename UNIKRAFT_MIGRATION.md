# Umzug auf Unikraft Cloud

Status: Konto und kostenloser Hobby-Tarif bestätigt; vollständiger Swift-Release-Build erfolgreich. Noch nicht auf Unikraft veröffentlicht: Die automatische Freigabeprüfung hat den Klick auf „Grant Access“ für die lokale CLI blockiert und verlangt dafür die ausdrückliche Zustimmung des Benutzers zur Organisation „Trail Atlas“. Es wurde keine Unikraft-Instanz erstellt. Die bestehende Render-Seite bleibt bis zur erfolgreichen Unikraft-Abnahme unter https://trailatlas-swift.onrender.com/ erreichbar.

## Nachgewiesener Stand vom 2. November 2026

- Die angemeldete Organisation `trailatlas` zeigt im tatsächlichen Abrechnungsdialog „Hobby“ und „This plan is free.“; Kontingent: zwei vCPUs, 4096 MB Speicher, fünf Instanzen. Nachweis: `reports/unikraft-account-preflight.json`.
- Die offizielle Unikraft-CLI 0.6.2 ist mit Hersteller-Prüfsumme verifiziert. Der lokale Deployment-Probelauf (`--dry-run`) akzeptiert Frankfurt, 512 MiB RAM, eine vCPU und die HTTP-/HTTPS-Portzuordnung; er verwendet nur einen Image-Platzhalter und erstellt keine Instanz. Nachweis: `reports/unikraft-preparation.json`.
- GitHub-Actions-Lauf `41508962423` hat Commit `ee5045d2f5950bf40df6da087afda43701811ad1` vollständig als Swift-Release-Server gebaut (161,85 Sekunden Swift-Buildzeit). Das exportierte Linux-x86_64-Laufzeitdateisystem wurde heruntergeladen und anhand seiner SHA-256-Prüfsumme geprüft. Größe des komprimierten Archivs: 114.465.531 Bytes. Nachweis: `reports/unikraft-rootfs-build.json`.
- Die 352 ursprünglichen Rennen und die originale HTML-Designreferenz sind bytegleich erhalten. Anwendungsquellcode und Ressourcen wurden für diesen Umzug nicht geändert. Das Image enthält keinen Sitzungsschlüssel.
- Die CI baut und exportiert ausschließlich das Docker-Laufzeitdateisystem. Unikraft-Zugangsdaten wurden nicht an GitHub übertragen. Die abschließende Unikraft-Paketierung und Veröffentlichung erfolgen nach der CLI-Freigabe mit dem lokalen Client.
- Das heruntergeladene Archiv liegt lokal bereit; das CI-Artefakt wird bis zum 5. November 2026, 19:23 UTC aufbewahrt. Der Build ist aus dem angegebenen Commit reproduzierbar.

## Festgelegter Betriebsweg

- Der im tatsächlichen Konto bestätigte kostenlose Hobby-Tarif. Kein kostenpflichtiges Upgrade, keine zusätzlichen kostenpflichtigen Datenträger oder Dienste.
- Eine Instanz in Frankfurt (`fra`), zunächst 512 MiB RAM und eine vCPU. Öffentlich HTTPS 443 auf den Swift-Port 10000; HTTP 80 leitet auf HTTPS um.
- `Kraftfile` verwendet das bestehende Dockerfile, die generische Kompatibilitätslaufzeit und EROFS. Für die lokale Paketierung ohne Docker steht eine temporäre Kraftfile-Variante mit dem geprüften Tarball als Rootfs-Quelle bereit. Ein ausdrücklicher Wechsel nach `/app` erhält den relativen Zugriff auf `Resources`.
- Swift, Hummingbird, Elementary, die 352 ursprünglichen Rennen und die skriptfreie Oberfläche bleiben erhalten. Keine Änderungen am Anwendungs-Quellcode oder an den Originalressourcen für diese Vorbereitung.
- Tangled bleibt Hauptrepository; der öffentliche Datenbranch und seine laufenden Quellenprüfungen bleiben zuständig.
- `SESSION_SECRET` wird erst zur Laufzeit als Geheimnis gesetzt und weder in das Image noch in die Konfiguration geschrieben.

## Noch ausstehende Schritte

1. Ausdrückliche Zustimmung zum CLI-Zugriff auf die Organisation „Trail Atlas“ einholen und den blockierten „Grant Access“-Schritt erst danach ausführen. Bei abgelaufener Anmeldeanfrage ist danach eine neue reguläre Anfrage erforderlich.
2. Das bereits geprüfte Swift-Laufzeitdateisystem mit der Unikraft-Kompatibilitätslaufzeit paketieren, hochladen und innerhalb des kostenlosen Kontingents starten. Der erfolgreiche Linux-/Swift-Build allein weist noch keine Kompatibilität mit der Unikraft-Laufzeit nach.
3. Eigenheiten der Unikraft-Laufzeit testen: Dateizugriff, Netzwerk, TLS-Abrufe, Threads und Swift NIO. Die Docker-Anweisung USER wird von der Kompatibilitätslaufzeit nicht automatisch als Laufzeitbenutzer übernommen; der Benutzerwechsel ist vor der Produktionsabnahme zu prüfen.
4. Quellenabruf von Tangled, `/health`, alle Filter und 352 Rennkarten, Favoriten, Ergebnisansichten, Export und Mobilansicht an der neuen HTTPS-Adresse prüfen.
5. Favoriten beim Wechsel der Domain ausdrücklich übernehmen: bestehende Cookies für `onrender.com` werden vom Browser nicht an die neue Domain gesendet. Ein unveränderter Sitzungsschlüssel allein löst diesen Domainwechsel nicht.
6. Erst nach bestandener Abnahme die neue Adresse als Hauptveröffentlichung setzen und den bisherigen Render-Betrieb als Rückfallmöglichkeit entsprechend dokumentieren.

## Aktuelle Referenzen

- Tarif: https://unikraft.com/pricing
- Übernahme eines Docker-Images: https://unikraft.com/docs/tutorials/docker-to-ukc
- Kraftfile v0.7: https://unikraft.com/docs/kraftfile/v0.7
- CLI: https://unikraft.com/docs/cli/overview
- Bauen: https://unikraft.com/docs/cli/unikraft/build
- Starten: https://unikraft.com/docs/cli/unikraft/run
