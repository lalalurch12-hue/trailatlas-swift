# Veröffentlichungsstatus

Öffentliche Website: https://trailatlas-swift.onrender.com/

Hauptrepository: https://tangled.org/lalalurch.tngl.sh/trailatlas-swift

- Swift, Hummingbird und Elementary laufen auf demselben kostenlosen Render-Dienst in Frankfurt.
- Der Render-Build lädt den festgelegten Tangled-Commit `eaddc37eefb69e95710b76479f499569fd5ef401` und prüft dessen Git-ID vor dem vollständigen Swift-Release-Build.
- Render weist die Tangled-Gitadresse als ungültig zurück. Der GitHub-Branch `render-bootstrap` enthält deshalb ausschließlich Dockerfile und README; er ist weiterhin als Build-Einstieg nötig.
- Tangled Spindle baut und prüft den Server einschließlich aller 352 Karten. Der Cachefehler durch unterschiedliche Dateieigentümer ist behoben und ein gespeicherter Build-Cache ist nachgewiesen.
- Quellenprüfungen und der öffentliche Datenbranch laufen auf Tangled. Ein tatsächlich geplanter Lauf und die Sicherung ohne persönliche Sessions sind nachgewiesen.
- `SHARED_DATA_BASE_URL` zeigt auf Tangled. Render verwendet `/health` als HTTP-Healthcheck.
- Der stabile Sitzungsschlüssel wurde beibehalten; die browsergebundene Wiederherstellung persönlicher Daten bleibt erhalten.
- GitHub-Zeitpläne werden durch manuell startbare Kompatibilitätsprüfungen ersetzt. Der temporäre Übertragungsschlüssel wird nach der abschließenden Übernahme aus GitHub entfernt.

Die öffentliche Abnahme und unvermeidbaren Einschränkungen stehen in `PRUEFBERICHT.md`. Es wurden keine kostenpflichtigen Dienste eingerichtet.
