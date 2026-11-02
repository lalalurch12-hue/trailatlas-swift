# Umzug auf Unikraft Cloud

Status: vorbereitet, noch nicht auf Unikraft veröffentlicht. Die offizielle Unikraft-CLI 0.6.2 ist mit Hersteller-Prüfsumme verifiziert; der lokale Deployment-Probelauf (`--dry-run`) akzeptiert Frankfurt, 512 MiB RAM, eine vCPU und die HTTP-/HTTPS-Portzuordnung. Er verwendet ausdrücklich einen Platzhalter für das noch zu bauende Image und erstellt keine Instanz. Details: `reports/unikraft-preparation.json`. Die bestehende Render-Seite bleibt bis zur erfolgreichen Unikraft-Abnahme erreichbar.

## Festgelegter Betriebsweg

- Kostenloser Hobby-Tarif; die tatsächlich zugeteilten Kontogrenzen werden vor der Bereitstellung in der Konsole geprüft. Kein kostenpflichtiges Upgrade, keine zusätzlichen kostenpflichtigen Datenträger oder Dienste.
- Eine Instanz in Frankfurt (`fra`), zunächst 512 MiB RAM und eine vCPU. Öffentlich HTTPS 443 auf den Swift-Port 10000; HTTP 80 leitet auf HTTPS um.
- `Kraftfile` verwendet das bestehende Dockerfile, die generische Kompatibilitätslaufzeit und EROFS. Ein ausdrücklicher Wechsel nach `/app` erhält den relativen Zugriff auf `Resources`.
- Swift, Hummingbird, Elementary, die 352 ursprünglichen Rennen und die skriptfreie Oberfläche bleiben erhalten. Keine Änderungen am Anwendungs-Quellcode oder an den Originalressourcen für diese Vorbereitung.
- Tangled bleibt Hauptrepository; der öffentliche Datenbranch und seine laufenden Quellenprüfungen bleiben zuständig.
- `SESSION_SECRET` wird erst zur Laufzeit als Geheimnis gesetzt und weder in das Image noch in die Konfiguration geschrieben.

## Noch ausstehende Schritte

1. Anmeldung bei Unikraft über die bereitstehende Browser-Konsole; eine gegebenenfalls erforderliche erstmalige Zustimmung zu den Nutzungsbedingungen erfolgt durch den Benutzer.
2. Hobby-Tarif und Kontingente im tatsächlichen Konto bestätigen, CLI autorisieren und das Swift-/Unikraft-Image bauen.
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
