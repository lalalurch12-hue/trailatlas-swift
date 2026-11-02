#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
SWIFT_FILES=(Sources/TrailAtlas/Core.swift Sources/TrailAtlas/DateExtraction.swift Sources/TrailAtlas/PublicHTTP.swift Sources/TrailAtlas/ProviderResults.swift Sources/TrailAtlas/TrackingDiscovery.swift Sources/TrailAtlas/LiveResults.swift Sources/TrailAtlas/InlineResults.swift Sources/TrailAtlas/UI.swift tests/ElementaryShim.swift)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
for TEST in core_checks tracking_checks refresh_checks approved_date_test date_checks; do
  echo "TEST: $TEST"
  swiftc "${SWIFT_FILES[@]}" "tests/$TEST.swift" -o "$TMP/$TEST"
  "$TMP/$TEST" "$ROOT"
done
python3 - <<'PY'
from pathlib import Path
from html.parser import HTMLParser
import json
class Scripts(HTMLParser):
    scripts=[]; handlers=[]
    def handle_starttag(self,tag,attrs):
        if tag=='script':self.scripts.append(attrs)
        for k,v in attrs:
            if k.lower().startswith('on') or (v or '').lower().startswith('javascript:'):self.handlers.append((k,v))
p=Path('Resources/template.html')
x=Scripts();x.feed(p.read_text())
assert not x.scripts, f'Scripts in active template: {x.scripts}'
assert not x.handlers, f'JS handlers: {x.handlers}'
r=json.loads(Path('Resources/races.json').read_text())
assert len(r)==352
print('PASS: Aktive HTML-Vorlage ohne JavaScript, 352 Einträge')
PY
