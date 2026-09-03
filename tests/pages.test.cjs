const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

class ProjectPageDriver {
    constructor() {
        this.html = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8');
    }

    analyticsLoaders() {
        return [...this.html.matchAll(/<script\b[^>]*src="(https:\/\/www\.googletagmanager\.com\/gtag\/js\?id=[^"]+)"[^>]*>/g)];
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
