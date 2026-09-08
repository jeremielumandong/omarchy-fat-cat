const test = require('node:test');
const assert = require('node:assert/strict');
const M = require('../SessionModel.js');
const NOW = 100000000;
const start = () => M.start(M.initial(), NOW);
test('default focus deadline and ceil countdown', () => {
  const s = start();
  assert.equal(s.phase, 'focus'); assert.equal(M.remaining(s, NOW), 1500);
  assert.equal(M.remaining(s, NOW + 1), 1500); assert.equal(M.format(65), '01:05');
});
test('focus completion starts full break; natural break earns one reward', () => {
  const f = start(); const b = M.tick(f, f.deadline);
  assert.equal(b.phase, 'break'); assert.equal(b.completedFocus, 1); assert.equal(b.completedBreaks, 0);
  assert.equal(M.remaining(b, f.deadline), 300);
  const f2 = M.tick(b, b.deadline); assert.equal(f2.completedBreaks, 1); assert.equal(f2.phase, 'focus');
  assert.equal(M.tick(f2, b.deadline).completedBreaks, 1);
});
test('every fourth focus gives long break', () => {
  let s = start();
  for (let i = 1; i <= 4; i++) {
    s = M.tick(s, s.deadline); assert.equal(s.durationSeconds, i === 4 ? 900 : 300);
    s = M.tick(s, s.deadline);
  }
  assert.equal(s.completedBreaks, 4);
});
test('skip, stop, and repeated start cannot award breaks', () => {
  const f = start(); assert.equal(M.start(f, NOW + 10), f);
  const b = M.tick(f, f.deadline); const skipped = M.skipBreak(b, b.deadline - 1);
  assert.equal(skipped.completedBreaks, 0); assert.equal(skipped.phase, 'focus');
  assert.equal(M.stop(b).completedBreaks, 0); assert.equal(M.stop(b).phase, 'idle');
});
test('pause and persisted restore freeze exact remaining seconds', () => {
  const p = M.pause(start(), NOW + 40000); assert.equal(p.remainingSeconds, 1460);
  const restored = M.restore(JSON.stringify(p), NOW + 999999999); assert.deepEqual(restored, p);
  const r = M.resume(restored, NOW + 999999999); assert.equal(M.remaining(r, NOW + 999999999), 1460);
});
test('overdue restore never replays multiple missed cycles', () => {
  const f = start(), later = NOW + 999999999;
  const b = M.restore(f, later); assert.equal(b.phase, 'break'); assert.equal(b.completedFocus, 1); assert.equal(M.remaining(b, later), 300);
  const r = M.restore(b, later + 999999999); assert.equal(r.phase, 'focus'); assert.equal(r.completedBreaks, 1); assert.equal(M.remaining(r, later + 999999999), 1500);
});
test('configuration affects next interval and rejects invalid values', () => {
  const s = start(); const c = M.configure(s, 50, 10, 30, 3);
  assert.equal(c.deadline, s.deadline); assert.equal(c.focusMinutes, 50);
  assert.equal(M.configure(s, NaN, 1, 1, 2), s); assert.equal(M.configure(s, 1.2, 1, 1, 2), s);
  assert.equal(M.configure(s, 1, 1, 1, 0), s); assert.equal(M.configure(s, 181, 1, 1, 2), s);
});
test('malformed and inconsistent snapshots safely initialize', () => {
  for (const data of ['', '{', 'null', '{}', {...start(), version: 2}, {...start(), deadline: Infinity}, {...start(), completedBreaks: 5}, {...start(), durationSeconds: -1}, {...start(), paused: true}]) {
    assert.deepEqual(M.restore(data, NOW), M.initial());
  }
});
test('backward clock moves are capped at full interval', () => {
  const s = M.tick(start(), NOW - 100000000); assert.equal(M.remaining(s, NOW - 100000000), 1500);
  assert.equal(s.deadline, 1500000);
});
test('all model mutations preserve valid state and source immutability', () => {
  const s = start(), before = JSON.stringify(s);
  for (const next of [M.stop(s), M.pause(s, NOW + 30000), M.tick(s, s.deadline), M.configure(s, 40, 8, 20, 5)]) assert.ok(M.valid(next));
  assert.equal(JSON.stringify(s), before);
});
