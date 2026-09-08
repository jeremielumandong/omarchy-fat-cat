// Pure session state: deadlines include suspend time; transitions never replay missed cycles.
function integer(value, minimum, maximum) {
    return typeof value === "number" && isFinite(value) && Math.floor(value) === value && value >= minimum && value <= maximum;
}
function initial() {
    return { version: 1, phase: "idle", paused: false, deadline: 0,
        remainingSeconds: 0, durationSeconds: 0, focusMinutes: 25,
        breakMinutes: 5, longBreakMinutes: 15, longBreakEvery: 4,
        completedFocus: 0, completedBreaks: 0 };
}
function copy(state) { return JSON.parse(JSON.stringify(state)); }
function valid(s) {
    if (!s || s.version !== 1 || ["idle", "focus", "break"].indexOf(s.phase) < 0 || typeof s.paused !== "boolean") return false;
    if (!integer(s.focusMinutes, 1, 180) || !integer(s.breakMinutes, 1, 180) || !integer(s.longBreakMinutes, 1, 180) || !integer(s.longBreakEvery, 2, 12)) return false;
    if (!integer(s.completedFocus, 0, 1000000000) || !integer(s.completedBreaks, 0, s.completedFocus)) return false;
    if (!integer(s.durationSeconds, 0, 10800) || !integer(s.remainingSeconds, 0, s.durationSeconds) || !integer(s.deadline, 0, 8640000000000000)) return false;
    if (s.phase === "idle") return !s.paused && s.deadline === 0 && s.remainingSeconds === 0 && s.durationSeconds === 0;
    return s.durationSeconds >= 60 && (s.paused ? s.deadline === 0 && s.remainingSeconds > 0 : s.deadline > 0);
}
function remaining(s, now) {
    if (s.phase === "idle") return 0;
    if (s.paused) return s.remainingSeconds;
    return Math.max(0, Math.min(s.durationSeconds, Math.ceil((s.deadline - now) / 1000)));
}
function format(seconds) {
    return String(Math.floor(seconds / 60)).padStart(2, "0") + ":" + String(seconds % 60).padStart(2, "0");
}
function enter(s, phase, minutes, now) {
    s.phase = phase; s.paused = false; s.durationSeconds = minutes * 60;
    s.remainingSeconds = s.durationSeconds; s.deadline = now + s.durationSeconds * 1000;
    return s;
}
function tick(state, now) {
    if (state.phase === "idle" || state.paused) return state;
    // Moving the wall clock backward cannot extend a session beyond its full interval.
    if (state.deadline - now > state.durationSeconds * 1000) {
        var adjusted = copy(state); adjusted.deadline = now + adjusted.durationSeconds * 1000; return adjusted;
    }
    if (remaining(state, now) > 0) return state;
    var s = copy(state);
    if (s.phase === "focus") {
        s.completedFocus = Math.min(1000000000, s.completedFocus + 1);
        return enter(s, "break", s.completedFocus % s.longBreakEvery === 0 ? s.longBreakMinutes : s.breakMinutes, now);
    }
    s.completedBreaks = Math.min(s.completedFocus, s.completedBreaks + 1);
    return enter(s, "focus", s.focusMinutes, now);
}
function restore(value, now) {
    try {
        var s = typeof value === "string" ? JSON.parse(value) : value;
        return valid(s) ? tick(copy(s), now) : initial();
    } catch (_) { return initial(); }
}
function start(state, now) { return state.phase === "idle" ? enter(copy(state), "focus", state.focusMinutes, now) : state; }
function stop(state) {
    var s = copy(state); s.phase = "idle"; s.paused = false;
    s.deadline = 0; s.remainingSeconds = 0; s.durationSeconds = 0; return s;
}
function pause(state, now) {
    var current = tick(state, now);
    if (current.phase === "idle" || current.paused) return current;
    var s = copy(current); s.remainingSeconds = remaining(s, now); s.deadline = 0; s.paused = true; return s;
}
function resume(state, now) {
    if (!state.paused) return state;
    var s = copy(state); s.paused = false; s.deadline = now + s.remainingSeconds * 1000; return s;
}
function skipBreak(state, now) {
    if (state.phase !== "break") return state;
    return enter(copy(state), "focus", state.focusMinutes, now);
}
function configure(state, focus, rest, longRest, every) {
    if (!integer(focus, 1, 180) || !integer(rest, 1, 180) || !integer(longRest, 1, 180) || !integer(every, 2, 12)) return state;
    var s = copy(state); s.focusMinutes = focus; s.breakMinutes = rest;
    s.longBreakMinutes = longRest; s.longBreakEvery = every; return s;
}
if (typeof module !== "undefined") module.exports = { initial: initial, valid: valid, remaining: remaining, format: format, tick: tick, restore: restore, start: start, stop: stop, pause: pause, resume: resume, skipBreak: skipBreak, configure: configure };
