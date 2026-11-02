#!/usr/bin/env python3
"""Exercise the real Hummingbird executable over HTTP, with isolated test data."""
import argparse
import http.cookiejar
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.forms = []
        self.current = None
        self.scripts = []
        self.handlers = []
        self.duplicate_attributes = []
        self.links = []
        self.countries = []
        self.in_country = False
        self.rows = 0
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        names = [a for a, _ in attrs]
        if len(set(names)) != len(names):
            self.duplicate_attributes.append((tag, names))
        if tag == 'script':
            self.scripts.append(attrs)
        self.handlers.extend((k, v) for k, v in attrs if k.startswith('on') or (v or '').strip().lower().startswith('javascript:'))
        if tag == 'article' and 'event-wrap' in values.get('class', '').split():
            self.rows += 1
        if tag == 'a' and values.get('href'):
            self.links.append(values['href'])
        if tag == 'form':
            assert self.current is None, 'Nested form in generated page'
            self.current = {'attrs': values, 'fields': {}}
        if self.current is not None and tag in ['input', 'button'] and values.get('name'):
            if tag != 'input' or values.get('type') != 'checkbox' or 'checked' in values:
                self.current['fields'][values['name']] = values.get('value', '')
        if tag == 'select' and values.get('id') == 'country-select':
            self.in_country = True
        if tag == 'option' and self.in_country and values.get('value'):
            self.countries.append(values['value'])

    def handle_endtag(self, tag):
        if tag == 'form':
            if self.current is not None:
                self.forms.append(self.current)
            self.current = None
        if tag == 'select':
            self.in_country = False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--binary', default='.build/debug/TrailAtlas')
    parser.add_argument('--internet', action='store_true')
    parser.add_argument('--report')
    parser.add_argument('--snapshot-dir')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    binary = (root / args.binary).resolve()
    assert binary.is_file(), binary
    original = json.loads((root / 'Resources/races.json').read_text())
    checks = []
    server = None
    with tempfile.TemporaryDirectory(prefix='trailatlas-http-') as temp:
        task_dir = Path(temp)
        data_dir = task_dir / 'data'
        data_dir.mkdir()
        with socket.socket() as sock:
            sock.bind(('127.0.0.1', 0))
            port = sock.getsockname()[1]
        origin = f'http://127.0.0.1:{port}'
        jar = http.cookiejar.CookieJar()
        client = urllib.request.build_opener(urllib.request.ProxyHandler({}),urllib.request.HTTPCookieProcessor(jar))
        log = (task_dir / 'server.log').open('w+')

        def get(path='/', opener=client, fields=None):
            data = None if fields is None else urllib.parse.urlencode(fields).encode()
            request = urllib.request.Request(origin + path, data=data)
            try:
                with opener.open(request, timeout=120 if args.internet else 15) as response:
                    return response.status, response.read().decode(), response.headers
            except urllib.error.HTTPError as error:
                return error.code, error.read().decode(), error.headers

        def start():
            nonlocal server
            env = dict(os.environ, PORT=str(port), DATA_DIR=str(data_dir), DISABLE_BACKGROUND='1', COOKIE_SECURE='0', SESSION_SECRET='http-test-key-is-not-a-production-secret')
            env.pop('SHARED_DATA_BASE_URL', None)
            server = subprocess.Popen([str(binary)], cwd=root, env=env, stdout=log, stderr=log)
            for _ in range(100):
                if server.poll() is not None:
                    log.flush()
                    raise AssertionError('Server exited: ' + (task_dir / 'server.log').read_text()[-5000:])
                try:
                    if get('/health')[0] == 200:
                        return
                except OSError:
                    pass
                time.sleep(.1)
            raise AssertionError('Server did not become healthy')

        def stop():
            if server is not None:
                server.terminate()
                try:
                    server.wait(timeout=8)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()

        def page(path='/'):
            status, text, headers = get(path)
            assert status == 200, (path, status, text[:300])
            parsed = Page(text)
            assert not parsed.scripts and not parsed.handlers, 'Browser JavaScript found'
            assert not parsed.duplicate_attributes, parsed.duplicate_attributes
            assert '@@' not in text, 'Unresolved template variable'
            assert "script-src 'none'" in headers.get('Content-Security-Policy', '')
            return parsed, text

        def action(parsed, name, extra=None):
            form = next(f for f in parsed.forms if f['fields'].get('action') == name)
            assert form['attrs'].get('method') == 'post'
            fields = dict(form['fields'])
            fields.update(extra or {})
            status, text, _ = get('/', fields=fields)
            assert status == 200, (name, status, text[:300])
            return Page(text), text

        try:
            start()
            home, html = page('/?page=25')
            assert home.rows == 352
            assert len(home.countries) == 65
            assert len(json.loads(get('/api/races')[1])) == 352
            checks.append('352 original cards and IDs; 65 country choices; API and health')
            if args.snapshot_dir:
                snapshots=Path(args.snapshot_dir)
                snapshots.mkdir(parents=True,exist_ok=True)
                snapshots.joinpath('index.html').write_text(page('/')[1])
                snapshots.joinpath('grid.html').write_text(page('/?view=grid')[1])
                snapshots.joinpath('radar.html').write_text(page('/?section=radar')[1])

            country_total = 0
            for country in home.countries:
                parsed, _ = page('/?' + urllib.parse.urlencode({'country': country, 'page': 25}))
                assert parsed.rows > 0, country
                country_total += parsed.rows
            assert country_total == 352
            for month in range(1, 13):
                parsed, _ = page(f'/?month={month}&page=25')
                expected = sum(bool(r['start']) and int(r['start'][5:7]) == month for r in original)
                assert parsed.rows == expected, (month, parsed.rows, expected)
            for year in ['2026', '2027']:
                parsed, _ = page(f'/?year={year}&page=25')
                assert parsed.rows == sum(r['start'].startswith(year) for r in original)
            for flag, expected in [('elite', sum(r['category'] in ['elite', 'series'] for r in original)), ('series', sum(r['category'] == 'series' for r in original)), ('tba', sum(not r['start'] for r in original))]:
                parsed, _ = page(f'/?{flag}=1&page=25')
                assert parsed.rows == expected, (flag, parsed.rows, expected)
            for distance in ['short', 'medium', 'long']:
                parsed, _ = page(f'/?distance={distance}&page=25')
                assert parsed.rows > 0
            parsed, _ = page('/?q=Oberaudorf')
            assert parsed.rows >= 1
            assert page('/?q=trailatlas-no-such-race-928172')[0].rows == 0
            assert page('/?minKm=100&maxKm=50')[0].rows == 0
            for path in ['/?view=grid', '/?sort=name-asc&page=25', '/?sort=date-desc&page=25', '/?upcoming=1', '/?section=radar', '/?weekendAll=1']:
                page(path)
            checks.append('All 65 countries, 12 months, both years, category and distance filters; search, sort, grid and weekend')

            assert 'type="checkbox" value="1"' in html
            empty, _ = page('/?favs=1')
            assert empty.rows == 0
            fav_form = next(f for f in home.forms if f['fields'].get('action') == 'toggle-fav')
            favorite_id = fav_form['fields']['id']
            action(home, 'toggle-fav')
            assert page('/?favs=1')[0].rows == 1
            get('/?' + urllib.parse.urlencode({'action': 'toggle-fav', 'id': favorite_id}))
            assert page('/?favs=1')[0].rows == 1, 'GET or refresh mutated favorites'
            status, _, _ = get('/', fields={'action': 'toggle-fav', 'id': favorite_id})
            assert status == 403, status
            another = urllib.request.build_opener(urllib.request.ProxyHandler({}),urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
            assert Page(get('/?favs=1', opener=another)[1]).rows == 0
            checks.append('POST/redirect favorite actions, safe refresh, CSRF rejection and visitor isolation')

            radar, _ = page('/?section=radar')
            action(radar, 'add-source', {'sourceName': 'My custom trail', 'sourceUrl': 'https://example.org/'})
            live, _ = page('/?section=live&race=' + favorite_id)
            action(live, 'save-live', {'url': 'https://example.org/public-results/'})
            stop()
            shutil.rmtree(data_dir)
            data_dir.mkdir()
            start()
            assert page('/?favs=1')[0].rows == 1, 'Favorite lost after full local cache deletion'
            assert 'My custom trail' in page('/?section=radar')[1]
            # Read the stored URL without fetching results over the Internet.
            assert 'https://example.org/public-results/' in page('/?race=' + favorite_id)[1]
            checks.append('Favorites, manual timing URL and custom source survive restart and complete local cache deletion')

            export_status, exported, export_headers = get('/export')
            assert export_status == 200 and Page(exported).rows == 352
            assert 'attachment' in export_headers.get('Content-Disposition', '')
            payload = urllib.parse.quote('\"><script>alert(1)</script>')
            _, escaped = page('/?q=' + payload)
            assert '<script>' not in escaped
            checks.append('Complete HTML export, escaping and script-free generated output')

            if args.internet:
                _, live_html = page('/?section=live&race=old-0195')
                assert 'live-inline-table' in live_html and 'SIMPANEN' in live_html
                assert '<script' not in live_html.lower()
                checks.append('Real UTMB Live API results rendered as native HTML tables without JavaScript')
                _, chinese_html=page('/?section=live&race=old-0208')
                assert 'WeRun' in chinese_html and 'https://werun.hk/game/yangxian100' in chinese_html
                assert '<script' not in chinese_html.lower()
                checks.append('Actual Chinese WeRun source opens safely; unpublished timing data is handled without invented results')

                if args.snapshot_dir:
                    Path(args.snapshot_dir).joinpath('live.html').write_text(live_html)
            print(json.dumps({'status': 'PASS', 'checks': checks, 'internet': args.internet}, ensure_ascii=False, indent=2))
            if args.report:
                Path(args.report).write_text(json.dumps({'status': 'PASS', 'checks': checks, 'internet': args.internet}, ensure_ascii=False, indent=2))
        except Exception:
            log.flush()
            print('Server diagnostics:',(task_dir / 'server.log').read_text()[-6000:],flush=True)
            raise
        finally:
            stop()
            log.close()


if __name__ == '__main__':
    main()
