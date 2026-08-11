import test from 'node:test';
import assert from 'node:assert/strict';
import {
  qualityProfile,
  layoutAgents,
  normalizeAgent,
  advancePatrol,
  whipPhase,
} from '../web/office3d-core.mjs';

test('quality profile caps pixel ratio and reduces expensive effects on small panes', () => {
  assert.deepEqual(qualityProfile({ width: 700, height: 420, dpr: 2 }), {
    pixelRatio: 1,
    shadows: false,
    particles: 18,
  });
  assert.deepEqual(qualityProfile({ width: 1440, height: 900, dpr: 2 }), {
    pixelRatio: 1.5,
    shadows: true,
    particles: 36,
  });
});

test('agent layout reserves the executive lounge and provides unique desks', () => {
  const seats = layoutAgents(8);
  assert.equal(seats.length, 8);
  assert.equal(new Set(seats.map(({ x, z }) => `${x},${z}`)).size, 8);
  assert.ok(seats.every(({ x }) => x <= 5), 'employee desks must leave the right lounge clear');
});

test('agent normalization is stable and handles incomplete live state', () => {
  const a = normalizeAgent({ id: 'abc', label: '', status: 'unexpected' });
  assert.deepEqual(a, {
    id: 'abc', label: 'agent abc', kind: 'main', status: 'idle',
    activity: 'idle', tool: '', detail: '',
  });
});

test('patrol moves Teknium from lounge to employee, strikes once, then returns', () => {
  let state = { phase: 'home', x: 9, z: 5, nextAt: 0, targetId: null, struck: false };
  const targets = [{ id: 'worker', x: 0, z: 0 }];
  let strikes = 0;
  let strikeDistance = 0;
  for (let now = 0; now < 30; now += 0.1) {
    const out = advancePatrol(state, targets, 0.1, now, { x: 9, z: 5 });
    state = out.state;
    if (out.strikeTargetId) {
      strikes += 1;
      strikeDistance = Math.hypot(state.x - targets[0].x, state.z - targets[0].z);
    }
    if (strikes === 1 && state.phase === 'home') break;
  }
  assert.equal(strikes, 1);
  assert.ok(strikeDistance >= 3, 'Teknium must stand far enough away for the rope to read');
  assert.equal(state.phase, 'home');
  assert.ok(Math.hypot(state.x - 9, state.z - 5) < 0.01);
});

test('3D whip exposes a readable cinematic window before cleanup', () => {
  assert.equal(whipPhase(0.1), 'windup');
  assert.equal(whipPhase(0.3), 'snap');
  assert.equal(whipPhase(0.6), 'impact');
  assert.equal(whipPhase(5), 'reaction');
  assert.equal(whipPhase(5.6), 'done');
});
