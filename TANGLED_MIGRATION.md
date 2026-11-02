# Tangled-Übernahme

Hauptrepository: https://tangled.org/lalalurch.tngl.sh/trailatlas-swift

Öffentliche Website: https://trailatlas-swift.onrender.com/

Quellcode und Git-Historie sind übertragen. Tangled Spindle baut und prüft Swift/Hummingbird/Elementary einschließlich aller 352 ursprünglichen Rennkarten, HTTP-Funktionen und persönlicher Wiederherstellung nach Cacheverlust. Der Cachefehler durch den Root-Benutzer im Docker-Container ist durch Rückgabe der Builddateien an den CI-Benutzer behoben. Der geprüfte Quellstand ist `eaddc37eefb69e95710b76479f499569fd5ef401`; spätere reine Berichtsänderungen ändern den veröffentlichten Laufzeitcode nicht.

Der öffentliche Datenbranch `trailatlas-data` wird durch Tangled-Zeitpläne ungefähr alle zwei Stunden gesichert. Ein tatsächlich geplanter Lauf und erfolgreiche Pushes sind nachgewiesen. Persönliche Sessions werden vor jedem Export ausgeschlossen. Die Anwendung liest die öffentlichen Raw-Dateien von Tangled; deren Weiterleitungen werden weiterhin auf öffentliche HTTPS-Ziele und öffentliche IP-Adressen geprüft.

## Verbleibende Render-Abhängigkeit

Render weist die Tangled-Gitadresse als ungültige Buildquelle zurück. Deshalb enthält der GitHub-Branch `render-bootstrap` nur Dockerfile und README. Dieser Einstieg lädt und prüft einen festgelegten Tangled-Commit, bevor Swift gebaut und die Originalressourcen kopiert werden. Neue Quellcodeveröffentlichungen benötigen eine Aktualisierung dieses Pins und einen Render-Deploy. Eine vollständig von GitHub unabhängige Render-Konfiguration wurde nicht erreicht. Die Termin- und Trackingsicherung funktioniert davon unabhängig über Tangled.

## Schlüssel

Der freigegebene Schlüssel `TrailAtlas Tangled automation 2026-11-02` hat den Fingerabdruck `SHA256:q9mRXI8is/+s2oetxesiuLySKAOChzXCY65MhzRleUA`. Sein privater Teil ist ausschließlich als CI-Geheimnis und in der privaten Arbeitskopie vorhanden; er ist nicht im Repository. Tangled verwendet die explizite SSH-Kontozuordnung `lalalurch.tngl.sh`. Ein temporäres GitHub-Geheimnis dient der abgeschlossenen Übertragungsphase und wird nach dem letzten Berichtstransfer entfernt. Im regulären Betrieb wird nur das Tangled-Geheimnis `TRAILATLAS_PUSH_KEY_B64` benötigt.

Die vollständige öffentliche Abnahme und Einschränkungen stehen in `PRUEFBERICHT.md`; maschinenlesbare Nachweise liegen im Ordner `reports`.
