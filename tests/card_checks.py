#!/usr/bin/env python3
"""Open every original race card on the real Swift HTTP server."""
import argparse
import html
import http.cookiejar
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
from http_checks import Page


def main():
    args=argparse.ArgumentParser()
    args.add_argument('--binary',default='.build/release/TrailAtlas')
    args.add_argument('--report')
    args.add_argument('--snapshot-dir')
    opt=args.parse_args()
    root=Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='trailatlas-cards-') as temp:
        with socket.socket() as sock:
            sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
        env=dict(os.environ,PORT=str(port),DATA_DIR=temp,DISABLE_BACKGROUND='1',SESSION_SECRET='card-test-secret-is-not-for-production')
        env.pop('SHARED_DATA_BASE_URL',None)
        env.pop('RENDER',None)
        client=urllib.request.build_opener(urllib.request.ProxyHandler({}),urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
        def get(path):
            with client.open(f'http://127.0.0.1:{port}'+path,timeout=15) as response:
                assert response.status==200
                return response.read().decode()
        with open(Path(temp)/'server.log','w+') as log:
            process=subprocess.Popen([str((root/opt.binary).resolve())],cwd=root,env=env,stdout=log,stderr=log)
            try:
                for _ in range(100):
                    if process.poll() is not None:
                        log.flush();raise AssertionError(Path(temp,'server.log').read_text())
                    try:
                        get('/health');break
                    except OSError:time.sleep(.1)
                races=json.loads(get('/api/races'))
                assert len(races)==352
                sources=0
                for index,race in enumerate(races):
                    query=urllib.parse.urlencode({'q':race['name'],'detail':race['id'],'page':'25'})
                    text=get('/?'+query)
                    parsed=Page(text)
                    assert f'class="event-extra open" id="details-{race["id"]}"' in text,race['name']
                    assert not parsed.scripts and not parsed.handlers and not parsed.duplicate_attributes
                    assert html.escape(race['name'],quote=True).replace('&#x27;','&#39;') in text
                    if race['source_url']:
                        assert race['source_url'] in parsed.links,race['name']
                        sources+=1
                    if index==0:
                        grid=get('/?'+query+'&view=grid')
                        assert 'events-grid' in grid and '.events-grid .event-extra.open{display:block!important' in grid
                        if opt.snapshot_dir:
                            path=Path(opt.snapshot_dir);path.mkdir(parents=True,exist_ok=True)
                            path.joinpath('grid-details.html').write_text(grid)
                report={'status':'PASS','raceCardsOpened':len(races),'originalSourceLinksPresent':sources,'gridDetailsRendered':True,'scriptFree':True}
                print(json.dumps(report,indent=2))
                if opt.report:Path(opt.report).write_text(json.dumps(report,indent=2))
            finally:
                process.terminate()
                try:process.wait(timeout=8)
                except subprocess.TimeoutExpired:process.kill();process.wait()


if __name__=='__main__':main()
