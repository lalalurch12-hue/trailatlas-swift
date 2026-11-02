# Tangled-Übernahme – vorbereitet, noch nicht umgeschaltet

Stand: 2. November 2026, Europe/Berlin.

Die Browser-Anmeldung für `lalalurch.tngl.sh` ist erfolgreich. Das neue, noch leere Repository ist unter https://tangled.org/lalalurch.tngl.sh/trailatlas-swift angelegt; Repository-DID: `did:plc:sew3yuioawady5nrhjvqmzix`. Als CI-Anbieter wurde `spindle.tangled.network` ausgewählt.

Die öffentliche Website bleibt bis zum bestandenen Wechsel unter https://trailatlas-swift.onrender.com/ in Betrieb. Der bisherige GitHub-Datenbranch bleibt die aktive Sicherung. Eine abgeschlossene Migration wird erst nach übertragenen Branches, erfolgreichen Tangled-Prüfungen und dem tatsächlich umgestellten Render-Dienst bestätigt.

## Vorbereitete Änderungen

- `.tangled/workflows/trailatlas.yml`: Swift-Docker-Build und bestehende Kern-, HTTP- und 352-Kartenprüfungen; rotierende öffentliche Quellenprüfung mit Speicherung im eigenen Datenbranch. Zeitplan: Minute 17 alle zwei Stunden, UTC. Ausführung und kostenlos verfügbares Kontingent müssen auf dem tatsächlichen Spindle geprüft werden.
- `.tangled/workflows/public-https.yml`: manuell startbare Abnahme der veröffentlichten Website mit den bestehenden 462 HTTPS-Anfragen.
- `SharedData.swift`: zusätzlich Tangled als Datenquelle zulassen. Raw-Dateien werden von Tangled auf `api.tangled.org` weitergeleitet; DNS/IP-Prüfung bleibt für jeden Weiterleitungs-Schritt aktiv.
- `render.yaml`: Zielrepository und öffentliche Datenadresse vorbereitet. Produktionswerte wurden noch nicht umgestellt.
- Einmaliger GitHub-Bootstrap: vorhandene Historie, Branches und Tags per Git an das neue Tangled-Repository übertragen; keine erzwungenen Pushes. Das Skript überträgt ohne konfigurierten Schlüssel ausdrücklich keine Dateien.

## Noch erforderliche Kontofreigabe

Der neue öffentliche SSH-Schlüssel heißt `TrailAtlas Tangled automation 2026-11-02` und hat den Fingerabdruck `SHA256:q9mRXI8is/+s2oetxesiuLySKAOChzXCY65MhzRleUA`.

Das Hinzufügen zu Tangled würde Git-Schreibzugriff für Repositories gewähren, auf die dieses Konto Schreibrechte besitzt; eine Einschränkung dieses Kontoschlüssels allein auf den Datenbranch ist nicht bestätigt. Der private Schlüssel ist nicht im Repository und wurde noch nicht an einen CI-Anbieter übermittelt.

Für den vorbereiteten Betriebsweg würde der private Teil einmalig als `TANGLED_BOOTSTRAP_KEY_B64` im bestehenden GitHub-Repository und dauerhaft als `TRAILATLAS_PUSH_KEY_B64` im Tangled-Repository gespeichert. Der temporäre GitHub-Eintrag soll nach erfolgreicher Übertragung entfernt werden. Der Tangled-Eintrag ermöglicht den geplanten Prüfläufen das Schreiben des öffentlichen Datenbranchs; die Skripte veröffentlichen keine privaten Sessions. Vor diesem neuen Kontozugriff und der Schlüsselübermittlung ist eine ausdrückliche Bestätigung erforderlich.

Die Shell-Skripte wurden syntaktisch und die Tangled-YAML-Dateien lokal auf gültiges YAML sowie Engine und Trigger geprüft. Der vollständige Release-Build des vorbereiteten Swift-Quellstands und seine HTTP-Regressionen sind im GitHub-Lauf [41465255217](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41465255217) erfolgreich durchgelaufen; die Kartenprüfung war bei dieser Zwischenaktualisierung noch aktiv. Der Quellenlauf [41465255202](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41465255202) ist erfolgreich.

Der Bootstrap-Vorlauf [41465255218](https://github.com/lalalurch12-hue/trailatlas-swift/actions/runs/41465255218) erreichte den Tangled-SSH-Server und hielt ausdrücklich vor der Übertragung an, weil kein privater Schlüssel konfiguriert ist. Der dabei aufgenommene öffentliche Server-Schlüssel ist in `.tangled/ssh_known_hosts` festgehalten; Fingerabdruck `SHA256:fLyp6ivr5HqmGI8yJiPYstTiJa2AXF/RAa9kF/ur1xo`. Die Vorbereitung ist noch kein erfolgreicher Tangled-CI-Lauf.
