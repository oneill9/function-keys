const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

class ProjectPageDriver {
    constructor() {
        this.html = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8');
        this.workflowPath = path.join(__dirname, '../.github/workflows/pages.yml');
    }

    analyticsLoaders() {
        return [...this.html.matchAll(/<script\b[^>]*src="(https:\/\/www\.googletagmanager\.com\/gtag\/js\?id=[^"]+)"[^>]*>/g)];
    }

    canonicalUrls() {
        return [...this.html.matchAll(/<link rel="canonical" href="([^"]+)"/g)].map((match) => match[1]);
    }

    sitemap() {
        return fs.readFileSync(path.join(__dirname, '../docs/sitemap.xml'), 'utf8');
    }

    sitemapUrls() {
        return [...this.sitemap().matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) => match[1]);
    }

    workflow() {
        return fs.readFileSync(this.workflowPath, 'utf8');
    }

    indexNowKeyFiles() {
        return fs.readdirSync(path.join(__dirname, '../docs'))
            .filter((name) => /^[0-9a-f]{32}\.txt$/.test(name));
    }

    indexNowPayload() {
        const match = this.workflow().match(/--data-binary\s+'(\{[\s\S]*?\})'/);
        return match ? JSON.parse(match[1]) : null;
    }

    reference(name) {
        return fs.readFileSync(path.join(__dirname, '../docs', name), 'utf8');
    }

    referenceLinks() {
        return [...this.html.matchAll(/<link rel="describedby" href="([^"]+)" type="([^"]+)"/g)]
            .map((match) => ({ url: match[1], type: match[2] }));
    }

    analyticsCommands() {
        const context = vm.createContext({ window: {} });
        const scripts = [...this.html.matchAll(/<script>([\s\S]*?)<\/script>/g)];
        const analytics = scripts.find((script) => script[1].includes("gtag('config'"));
        assert.ok(analytics, 'The page initializes Google Analytics');
        context.window = context;
        vm.runInContext(analytics[1], context);
        return JSON.parse(JSON.stringify(context.dataLayer.map((command) => [...command])));
    }
}

test('agents can discover both raw project references from the home page', () => {
    const page = new ProjectPageDriver();
    const baseUrl = 'https://oneill9.github.io/function-keys/';

    assert.deepEqual(page.referenceLinks(), [
        { url: `${baseUrl}llms.txt`, type: 'text/plain' },
        { url: `${baseUrl}llms.md`, type: 'text/markdown' }
    ]);
    for (const name of ['llms.txt', 'llms.md']) {
        const reference = page.reference(name);
        assert.match(reference, /^# Function Keys\n\n> /);
        assert.doesNotMatch(reference, /<!doctype|<html/i);
        assert.match(reference, /https:\/\/github.com\/oneill9\/function-keys/);
    }
    assert.ok(page.reference('llms.txt').includes(`](${baseUrl}llms.md)`));
    assert.match(page.reference('llms.md'), /macOS 13/);
    assert.match(page.reference('llms.md'), /30 seconds/);
});

test('search engines can discover the canonical project page through its sitemap', () => {
    const page = new ProjectPageDriver();
    const canonicalUrl = 'https://oneill9.github.io/function-keys/';

    assert.deepEqual(page.canonicalUrls(), [canonicalUrl]);
    assert.match(page.sitemap(), /<urlset xmlns="http:\/\/www.sitemaps.org\/schemas\/sitemap\/0.9">/);
    assert.deepEqual(page.sitemapUrls(), [canonicalUrl]);
});

test('IndexNow is notified after deployment for every sitemap URL', () => {
    const page = new ProjectPageDriver();
    const keyFiles = page.indexNowKeyFiles();

    assert.equal(keyFiles.length, 1);
    const key = path.basename(keyFiles[0], '.txt');
    assert.equal(page.reference(keyFiles[0]).trim(), key);
    assert.match(page.workflow(), /\n  indexnow:\n/);
    assert.match(page.workflow(), /needs: deploy/);
    assert.match(page.workflow(), /--fail-with-body/);
    assert.deepEqual(page.indexNowPayload(), {
        host: 'oneill9.github.io',
        key,
        keyLocation: `https://oneill9.github.io/function-keys/${key}.txt`,
        urlList: page.sitemapUrls()
    });
});

test('the project page immediately initializes its own analytics stream with isolated cookies', () => {
    const page = new ProjectPageDriver();
    const loaders = page.analyticsLoaders();

    assert.equal(loaders.length, 1);
    assert.equal(loaders[0][1], 'https://www.googletagmanager.com/gtag/js?id=G-C2BNP3XPXG');
    assert.match(loaders[0][0], /\basync\b/);
    const configurations = page.analyticsCommands().filter((command) => command[0] === 'config');
    assert.deepEqual(configurations, [['config', 'G-C2BNP3XPXG', {
        cookie_path: '/function-keys/',
        cookie_prefix: 'function_keys'
    }]]);
});
