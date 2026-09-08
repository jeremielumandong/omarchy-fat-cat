// Pure movement decisions, shared by QML and deterministic tests.
var activities = ['walk', 'stretch', 'groom', 'yawn', 'loaf', 'sleep'];
var personalities = ['Sleepy', 'Curious', 'Playful', 'Shy'];
function clamp(value, low, high) { return Math.max(low, Math.min(high, value)); }
function choices(available, favorites) {
    var allowed = (available || []).filter(function(v, i, a) {
        return Number.isInteger(v) && v >= 0 && v < 4 && a.indexOf(v) === i;
    });
    if (!allowed.length) allowed = [0];
    var selected = allowed.filter(function(v) { return (favorites || []).indexOf(v) >= 0; });
    return selected.length ? selected : allowed;
}
function create(variant, index, count, maxX, random, size) {
    var r = random || Math.random;
    var span = Math.max(0, size || 0);
    return { variant: variant, x: clamp((maxX + span) * (index + 0.5) / count - span / 2, 0, maxX),
        lane: count > 1 ? index / (count - 1) : 0.6,
        direction: r() < 0.5 ? -1 : 1,
        speed: [30, 52, 72, 36][variant] * (0.85 + r() * 0.3),
        activity: 'walk', remaining: 2 + r() * 4, hop: 0, greetingCooldown: 0 };
}
function decide(cat, random) {
    var r = random || Math.random;
    var weights = [
        [0.30, 0.08, 0.08, 0.14, 0.15, 0.25],
        [0.55, 0.10, 0.14, 0.06, 0.10, 0.05],
        [0.62, 0.12, 0.10, 0.05, 0.07, 0.04],
        [0.35, 0.10, 0.18, 0.08, 0.19, 0.10]
    ][cat.variant];
    var pick = r(), cumulative = 0, activity = 'sleep';
    for (var i = 0; i < weights.length; i++) {
        cumulative += weights[i];
        if (pick < cumulative) { activity = activities[i]; break; }
    }
    cat.activity = activity;
    cat.remaining = activity === 'sleep' ? 7 + r() * 8
        : activity === 'walk' ? 3 + r() * 5 : 2 + r() * 3;
    if (activity === 'walk') {
        cat.direction = r() < 0.5 ? -1 : 1;
        if (cat.variant === 2 && r() < 0.25) cat.hop = 0.55;
    }
}
function advance(state, seconds, maxX, peers, catSize, random) {
    var r = random || Math.random, cat = {};
    for (var key in state) cat[key] = state[key];
    var dt = clamp(seconds, 0, 0.1);
    cat.x = clamp(cat.x, 0, Math.max(0, maxX));
    cat.hop = Math.max(0, cat.hop - dt);
    cat.greetingCooldown = Math.max(0, cat.greetingCooldown - dt);
    cat.remaining -= dt;
    if (cat.remaining <= 0) decide(cat, r);
    if (cat.activity !== 'walk') { cat.hop = 0; return cat; }
    var near = (peers || []).filter(function(p) {
        return p !== state && Math.abs(p.lane - cat.lane) < 0.4
            && Math.abs(p.x - cat.x) < catSize * 0.75;
    });
    if (near.length && cat.greetingCooldown <= 0) {
        cat.greetingCooldown = 12;
        if (cat.variant === 3) cat.direction = near[0].x >= cat.x ? -1 : 1;
        else {
            cat.activity = 'groom'; cat.remaining = 2.5; cat.hop = 0;
            return cat;
        }
    }
    cat.x += cat.direction * cat.speed * dt;
    if (cat.x >= maxX) { cat.x = Math.max(0, maxX); cat.direction = -1; }
    else if (cat.x <= 0) { cat.x = 0; cat.direction = 1; }
    return cat;
}
