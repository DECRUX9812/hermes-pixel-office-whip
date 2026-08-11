const VALID_STATUS = new Set(['working', 'thinking', 'idle', 'waiting', 'done', 'gone']);
const VALID_ACTIVITY = new Set(['typing', 'reading', 'browsing', 'running', 'delegating', 'working', 'idle']);

export function qualityProfile({ width, height, dpr = 1 }) {
  const compact = width < 900 || height < 560;
  return {
    pixelRatio: Math.min(dpr, compact ? 1 : 1.5),
    shadows: !compact,
    particles: compact ? 18 : 36,
  };
}

export function layoutAgents(count) {
  const columns = 3;
  const seats = [];
  for (let i = 0; i < count; i += 1) {
    seats.push({
      x: -7 + (i % columns) * 5.5,
      z: -3.5 + Math.floor(i / columns) * 5,
      rotation: 0,
    });
  }
  return seats;
}

export function normalizeAgent(raw = {}) {
  const id = String(raw.id || 'unknown');
  const suffix = id.length > 10 ? id.slice(-6) : id;
  const status = VALID_STATUS.has(raw.status) ? raw.status : 'idle';
  const activity = VALID_ACTIVITY.has(raw.activity) ? raw.activity : (status === 'working' ? 'working' : 'idle');
  return {
    id,
    label: String(raw.label || `agent ${suffix}`),
    kind: raw.kind === 'subagent' ? 'subagent' : 'main',
    status,
    activity,
    tool: String(raw.tool || ''),
    detail: String(raw.detail || ''),
  };
}

export function whipPhase(age) {
  if (age < .2) return 'windup';
  if (age < .44) return 'snap';
  if (age < 1.15) return 'impact';
  if (age < 5.5) return 'reaction';
  return 'done';
}

function move(state, target, dt, speed = 4.2) {
  const dx = target.x - state.x;
  const dz = target.z - state.z;
  const distance = Math.hypot(dx, dz);
  if (distance <= speed * dt) return { ...state, x: target.x, z: target.z, arrived: true };
  return {
    ...state,
    x: state.x + (dx / distance) * speed * dt,
    z: state.z + (dz / distance) * speed * dt,
    arrived: false,
  };
}

export function advancePatrol(input, targets, dt, now, home) {
  let state = { ...input };
  let strikeTargetId = null;
  if (state.phase === 'home') {
    if (now >= state.nextAt && targets.length) {
      state.phase = 'patrol';
      state.targetId = targets[0].id;
      state.struck = false;
    }
  } else if (state.phase === 'patrol') {
    const target = targets.find(({ id }) => id === state.targetId);
    if (!target) {
      state.phase = 'return';
    } else {
      state = move(state, { x: target.x + 3.4, z: target.z + 1.7 }, dt);
      if (state.arrived) {
        state.phase = 'victory';
        state.returnAt = now + 1.5;
        state.struck = true;
        strikeTargetId = target.id;
      }
    }
  } else if (state.phase === 'victory') {
    if (now >= state.returnAt) state.phase = 'return';
  } else if (state.phase === 'return') {
    state = move(state, home, dt);
    if (state.arrived) {
      state.phase = 'home';
      state.targetId = null;
      state.struck = false;
      state.nextAt = now + 9;
    }
  }
  delete state.arrived;
  return { state, strikeTargetId };
}
