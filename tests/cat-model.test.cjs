const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const model = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, '../CatModel.js'), 'utf8'), model);
const plain = x => JSON.parse(JSON.stringify(x));
const constant = n => () => n;

test('selection never introduces locked cats and deduplicates favorites', () => {
    assert.deepEqual(plain(model.choices([0, 1], [1, 2, 1])), [1]);
    assert.deepEqual(plain(model.choices([0, 1], [3])), [0, 1]);
    assert.deepEqual(plain(model.choices([0, 0, -1, 4, '1'], [])), [0]);
});
test('initial positions are separated and bounded for every collection size', () => {
    for (let count = 1; count <= 4; count++) {
        const cats = Array.from({length: count}, (_, i) => model.create(i, i, count, 900, constant(.5)));
        for (let i = 0; i < count; i++) {
            assert.ok(cats[i].x >= 0 && cats[i].x <= 900);
            assert.ok(cats[i].lane >= 0 && cats[i].lane <= 1);
            if (i) assert.ok(cats[i].x - cats[i - 1].x >= 225);
        }
    }
});
test('all six activities reachable and sleepy versus playful decisions differ', () => {
    const reached = new Set();
    for (let variant = 0; variant < 4; variant++) {
        for (let n = 0; n < 1000; n++) {
            const cat = model.create(variant, 0, 1, 900, constant(.5));
            model.decide(cat, constant(n / 1000));
            reached.add(cat.activity);
        }
    }
    assert.deepEqual([...reached].sort(), ['groom', 'loaf', 'sleep', 'stretch', 'walk', 'yawn']);
    const sleepy = model.create(0, 0, 1, 900, constant(.5));
    const playful = model.create(2, 0, 1, 900, constant(.5));
    model.decide(sleepy, constant(.4)); model.decide(playful, constant(.4));
    assert.equal(sleepy.activity, 'groom');
    assert.equal(playful.activity, 'walk');
    assert.ok(playful.speed > sleepy.speed);
});
test('rest activities remain stationary and movement reflects at both edges', () => {
    const state = model.create(0, 0, 1, 900, constant(.5));
    for (const activity of ['stretch', 'groom', 'yawn', 'loaf', 'sleep']) {
        const next = model.advance({...state, activity}, .1, 900, [], 100, constant(.5));
        assert.equal(next.x, state.x);
    }
    assert.equal(model.advance({...state, x: 900, direction: 1}, .1, 900, [], 100).direction, -1);
    assert.equal(model.advance({...state, x: 0, direction: -1}, .1, 900, [], 100).direction, 1);
});
test('sleep/wake delays cannot teleport a cat and input state is immutable', () => {
    const state = model.create(0, 0, 1, 900, constant(.5));
    const saved = plain(state);
    const next = model.advance(state, 3600, 900, [], 100, constant(.5));
    assert.ok(Math.abs(next.x - state.x) <= state.speed * .1 + 1e-8);
    assert.deepEqual(plain(state), saved);
});
test('nearby cats greet briefly, while shy cats turn away', () => {
    const normal = {...model.create(1, 0, 1, 900, constant(.5)), x: 400};
    const peer = {...normal, x: 430};
    const greeting = model.advance(normal, .1, 900, [normal, peer], 100, constant(.5));
    assert.equal(greeting.activity, 'groom'); assert.equal(greeting.x, 400);
    const shy = {...normal, variant: 3};
    const next = model.advance(shy, .1, 900, [shy, peer], 100, constant(.5));
    assert.equal(next.activity, 'walk'); assert.equal(next.direction, -1);
});

test('small monitors initialize cats without horizontal overlap', () => {
    const size = 100, maxX = 300;
    const cats = Array.from({length: 4}, (_, i) => model.create(i, i, 4, maxX, constant(.5), size));
    for (let i = 1; i < cats.length; i++) assert.ok(cats[i].x - cats[i - 1].x >= size);
});
