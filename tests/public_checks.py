#!/usr/bin/env python3
"""Verify the deployed Swift service over HTTPS without deployment credentials."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import html
import http.cookiejar
import json
from pathlib import Path
import urllib.error
import urllib.parse
import urllib.request
import threading
from http_checks import Page


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--report', required=True)
    parser.add_argument('--cookie-file')
    parser.add_argument('--check-saved-favorite', action='store_true')
    args = parser.parse_args()
    origin = args.url.rstrip('/')
    url = urllib.parse.urlsplit(origin)
    assert url.scheme == 'https' and url.hostname and not url.username
    assert not url.path and not url.query and not url.fragment
    jar = http.cookiejar.MozillaCookieJar(args.cookie_file) if args.cookie_file else http.cookiejar.CookieJar()
    if args.cookie_file and Path(args.cookie_file).exists():
        jar.load(ignore_discard=True, ignore_expires=True)
    client = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    checks = []
    requests = 0
    cards_checked = 0
    request_lock = threading.Lock()

    def get(path='/', fields=None, opener=client):
        nonlocal requests
        with request_lock: requests += 1
        req = urllib.request.Request(origin+path,
            data=None if fields is None else urllib.parse.urlencode(fields).encode(),
            headers={'User-Agent':'TrailAtlas-Functional-Acceptance/1.0'})
        try:
            with opener.open(req, timeout=150) as response:
                assert response.url.startswith(origin+'/'), response.url
                return response.status, response.read().decode(), response.headers
        except urllib.error.HTTPError as error:
            return error.code, error.read().decode(), error.headers

    def page(path='/', opener=client):
        code, text, headers = get(path,opener=opener)
        assert code == 200, (path, code, text[:200])
        parsed = Page(text)
        assert not parsed.scripts and not parsed.handlers and not parsed.duplicate_attributes, path
        assert '@@' not in text, path
        assert "script-src 'none'" in headers.get('Content-Security-Policy',''), path
        return parsed, text

    def record(label):
        checks.append(label)
        print('PASS '+label, flush=True)

    try:
        assert get('/health')[0] == 200
        home, _ = page('/?page=25')
        races = json.loads(get('/api/races')[1])
        original = json.loads((Path(__file__).resolve().parents[1]/'Resources/races.json').read_text())
        ids = {r['id'] for r in races}
        assert len(original) == 352 and len(ids) == len(races)
        assert {r['id'] for r in original} <= ids
        assert home.rows == len(races) and len(home.countries) == 65
        code, status_text, _ = get('/api/status')
        assert code == 200
        public_status = json.loads(status_text)
        record('HTTPS, /health, public APIs and all 352 original race IDs')

        if args.check_saved_favorite:
            assert page('/?favs=1')[0].rows == 1, 'Favorite lost after server replacement'
            record('Saved secure-cookie favorite survives the actual server restart or redeployment')
        else:
            def check_country(country):
                reader=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
                subset, _ = page('/?'+urllib.parse.urlencode({'country':country,'page':25}),opener=reader)
                assert subset.rows > 0, country
                return subset.rows
            with ThreadPoolExecutor(max_workers=4) as pool:
                total=sum(pool.map(check_country,home.countries))
            assert total == len(races), (total,len(races))
            # The public calendar may gain dates while its initial scan completes.
            races = json.loads(get('/api/races')[1])
            for month in range(1,13):
                subset, _ = page(f'/?month={month}&page=25')
                expected = sum(bool(r['start']) and int(r['start'][5:7])==month for r in races)
                assert subset.rows == expected, (month,subset.rows,expected)
            for year in ['2026','2027']:
                assert page(f'/?year={year}&page=25')[0].rows == sum(r['start'].startswith(year) for r in races)
            for flag, count in [('elite',sum(r['category'] in ['elite','series'] for r in races)),
                                ('series',sum(r['category']=='series' for r in races)),
                                ('tba',sum(not r['start'] for r in races))]:
                assert page(f'/?{flag}=1&page=25')[0].rows == count, flag
            for distance in ['short','medium','long']:
                assert page(f'/?distance={distance}&page=25')[0].rows > 0
            assert page('/?q=Oberaudorf')[0].rows >= 1
            assert page('/?q=trailatlas-no-such-race-928172')[0].rows == 0
            assert page('/?minKm=100&maxKm=50')[0].rows == 0
            for path in ['/?view=grid','/?sort=name-asc&page=25','/?sort=date-desc&page=25',
                         '/?upcoming=1','/?section=radar','/?weekendAll=1']:
                page(path)
            record('All 65 countries, 12 months, years, categories, distances, search, sorts and views')

            def check_card(race):
                nonlocal cards_checked
                reader=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
                query = urllib.parse.urlencode({'q':race['name'],'detail':race['id'],'page':25})
                card, text = page('/?'+query,opener=reader)
                assert f'class="event-extra open" id="details-{race["id"]}"' in text, race['id']
                assert html.escape(race['name'],quote=True).replace('&#x27;','&#39;') in text
                if race['source_url']:
                    assert race['source_url'] in card.links, race['id']
                with request_lock:
                    cards_checked += 1
                    if cards_checked % 32 == 0:print(f'PROGRESS {cards_checked}/352 public race cards',flush=True)
                return int(bool(race['source_url']))
            with ThreadPoolExecutor(max_workers=4) as pool:
                source_count=sum(pool.map(check_card,original))
            record(f'All 352 detail cards and {source_count} original source links over public HTTPS')

            assert page('/?favs=1')[0].rows == 0
            form = next(f for f in home.forms if f['fields'].get('action')=='toggle-fav')
            assert form['attrs'].get('method') == 'post'
            assert get('/',fields=form['fields'])[0] == 200
            assert page('/?favs=1')[0].rows == 1
            favorite_id = form['fields']['id']
            get('/?'+urllib.parse.urlencode({'action':'toggle-fav','id':favorite_id}))
            assert page('/?favs=1')[0].rows == 1
            assert get('/',fields={'action':'toggle-fav','id':favorite_id})[0] == 403
            other = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
            assert Page(get('/?favs=1',opener=other)[1]).rows == 0
            assert any(c.secure and 'HttpOnly' in c._rest for c in jar)
            record('Favorite POST/redirect, safe GET, CSRF rejection, isolation and Secure HttpOnly cookies')

            code, exported, headers = get('/export')
            assert code == 200 and Page(exported).rows == len(races)
            assert 'attachment' in headers.get('Content-Disposition','')
            page('/?q='+urllib.parse.quote('\"><script>alert(1)</script>'))
            record('Complete HTML export and escaping; no browser scripts across tested pages')
            _, live = page('/?section=live&race=old-0195')
            assert 'live-inline-table' in live and 'SIMPANEN' in live
            assert 'http-equiv="refresh"' in live
            _, china = page('/?section=live&race=old-0208')
            assert 'WeRun' in china and 'https://werun.hk/game/yangxian100' in china
            record('Real UTMB API fetched by the Swift server and Chinese WeRun source displayed safely')

        if args.cookie_file:
            jar.save(ignore_discard=True,ignore_expires=True)
            Path(args.cookie_file).chmod(0o600)
        report={'status':'PASS','url':origin,'checkedAt':datetime.now(timezone.utc).isoformat(),
                'requests':requests,'originalRaces':352,'effectiveRaces':len(races),'checks':checks,
                'serverStatus':public_status}
        Path(args.report).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    except Exception as error:
        Path(args.report).write_text(json.dumps({'status':'FAIL','url':origin,
            'checkedAt':datetime.now(timezone.utc).isoformat(),'requests':requests,
            'checks':checks,'error':str(error)},ensure_ascii=False,indent=2)+'\n')
        raise


if __name__=='__main__':main()
