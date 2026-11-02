#!/usr/bin/env python3
"""Exercise the public server in isolated browsers with JavaScript disabled."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright, expect


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', required=True)
    parser.add_argument('--report-dir', required=True)
    args = parser.parse_args()
    origin = args.url.rstrip('/')
    parsed = urlsplit(origin)
    assert parsed.scheme == 'https' and parsed.hostname and not parsed.username
    assert not parsed.path and not parsed.query and not parsed.fragment
    destination = Path(args.report_dir)
    destination.mkdir(parents=True, exist_ok=True)
    results = []

    def check_width(page, width):
        geometry = page.evaluate('''() => ({
            viewport: innerWidth,
            document: document.documentElement.scrollWidth,
            body: document.body.scrollWidth
        })''')
        assert geometry['viewport'] == width, geometry
        assert max(geometry['document'], geometry['body']) <= width + 1, geometry
        assert page.locator('script').count() == 0
        return geometry

    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch()
            for width in [360, 390, 768, 1280]:
                context = browser.new_context(
                    viewport={'width': width, 'height': 900},
                    java_script_enabled=False, locale='de-DE',
                    timezone_id='UTC', reduced_motion='reduce')
                page = context.new_page()
                page.set_default_timeout(30000)
                for label, path in [
                    ('calendar', '/'),
                    ('grid', '/?view=grid'),
                    ('live', '/?section=live&race=old-0195'),
                ]:
                    response = page.goto(origin + path, wait_until='domcontentloaded', timeout=90000)
                    assert response and response.status == 200
                    assert "script-src 'none'" in response.headers.get('content-security-policy', '')
                    expect(page.locator('.brand')).to_be_visible()
                    geometry = check_width(page, width)
                    screenshot = f'{label}-{width}.png'
                    page.screenshot(path=str(destination / screenshot))
                    results.append({'width': width, 'view': label, 'geometry': geometry,
                                    'javascriptEnabled': False, 'screenshot': screenshot})

                page.goto(origin + '/', wait_until='domcontentloaded', timeout=90000)
                if width <= 900:
                    page.locator('#mobile-menu').click()
                    sidebar = page.locator('#sidebar').bounding_box()
                    assert sidebar and sidebar['x'] >= -1, sidebar
                page.locator('#search-input').fill('Oberaudorf')
                page.locator('#search-input').press('Enter')
                expect(page.locator('.event-name').first).to_contain_text('Oberaudorf')
                check_width(page, width)
                page.get_by_role('link', name='Details ▾', exact=True).first.click()
                expect(page.locator('.event-extra.open').first).to_be_visible()
                check_width(page, width)
                page.screenshot(path=str(destination / f'filter-details-{width}.png'))
                results.append({'width': width, 'view': 'filter-and-details',
                                'javascriptEnabled': False, 'mobileMenuTested': width <= 900})
                print(f'PASS {width}px: calendar, grid, live results, search and details with JavaScript disabled', flush=True)
                context.close()
            browser.close()
        report = {'status': 'PASS', 'url': origin, 'checkedAt': datetime.now(timezone.utc).isoformat(),
                  'checks': results}
    except Exception as error:
        report = {'status': 'FAIL', 'url': origin, 'checkedAt': datetime.now(timezone.utc).isoformat(),
                  'checks': results, 'error': str(error)}
        raise
    finally:
        (destination / 'browser-acceptance.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    main()
