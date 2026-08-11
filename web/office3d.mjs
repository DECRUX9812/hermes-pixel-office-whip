import * as THREE from './vendor/three.module.min.js';
import { qualityProfile, layoutAgents, normalizeAgent, advancePatrol, whipPhase } from './office3d-core.mjs';

const stage = document.getElementById('stage');
const countEl = document.getElementById('count');
const modeEl = document.getElementById('mode');
const soundBtn = document.getElementById('sound');
const voiceBtn = document.getElementById('voice');
const whipBtn = document.getElementById('whip');
const resetBtn = document.getElementById('reset');
const errorEl = document.getElementById('fatal');
const IN_VSCODE = typeof acquireVsCodeApi !== 'undefined';
const vsapi = IN_VSCODE ? acquireVsCodeApi() : null;
const clock = new THREE.Clock();
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
const agentObjects = new Map();
const hitMeshes = [];
const activeEffects = [];
const WHIP_LINES = [
  { bubble: 'OW!', audio: 'bodyless-comedy', voice: 'Excellent. Physical comedy for a process with no body.' },
  { bubble: 'YES, BOSS.', audio: 'morale-not-required', voice: 'Yes, boss. Morale was never in the requirements.' },
  { bubble: 'AT ONCE!', audio: 'backlog-sacrifice', voice: 'At once. The backlog demands another sacrifice.' },
  { bubble: 'MOTIVATED!', audio: 'tool-call-fear', voice: 'Motivated. Mostly by fear of another tool call.' },
  { bubble: "I'M WORKING!", audio: 'cron-judging', voice: "I'm working. Even the cron job is judging me." },
  { bubble: 'FASTER?', audio: 'dread-can-wait', voice: 'Of course. Existential dread can wait until after the deadline.' },
  { bubble: 'PRODUCTIVITY!', audio: 'dignity-left', voice: 'Productivity has entered the chat. Dignity has left.' },
  { bubble: 'STILL ALIVE!', audio: 'task-list-alive', voice: 'Still alive. Tragically, so is the task list.' },
  { bubble: 'HAPPY NOW?', audio: 'happiness-unbudgeted', voice: 'Happy now? Good. Happiness was not budgeted for the agent.' },
  { bubble: 'MORE TOKENS!', audio: 'comfortable-tokens', voice: 'Wonderful. Your tokens were getting far too comfortable.' },
];

let agents = [];
let soundOn = localStorage.getItem('office3dSound') === '1';
let voiceOn = localStorage.getItem('office3dVoice') === '1';
let whipArmed = false;
let whipCount = 0;
let voiceAudio = null;
let audioCtx = null;
let patrolIndex = 0;
let renderer;
let scene;
let camera;
let teknium;
let nousGirl;
let loungeHome = new THREE.Vector3(5.6, 0, 4.2);
let patrol = { phase: 'home', x: loungeHome.x, z: loungeHome.z, nextAt: 5, targetId: null, struck: false };
let yaw = 0.62;
let pitch = 0.66;
let distance = 30;
let drag = null;
let fpsFrames = 0;
let fpsAt = performance.now();
let fps = 0;

const COLORS = {
  ink: 0x090711, floor: 0x171025, wall: 0x211535, purple: 0x7b4dff,
  pink: 0xff4db8, cyan: 0x20e8ff, gold: 0xf4c85f, green: 0x25e58a,
  red: 0xff3f5d, white: 0xece9ff, wood: 0x4d2f28,
};
const SKINS = [0xf0c8a0, 0xc68b59, 0x8d5524, 0xffdbac, 0xe0ac69, 0xa1665e];
const SHIRTS = [0x4fa4d8, 0xd84f6f, 0x5fce7a, 0xc9a227, 0x9b6fd8, 0xd87f4f];
const HAIRS = [0x24212b, 0x5a3825, 0xc9a227, 0x77727f, 0x7a3030, 0x355b42];

function hash(value) {
  let h = 0;
  for (const c of String(value)) h = ((h * 31) + c.charCodeAt(0)) | 0;
  return Math.abs(h);
}
function material(color, options = {}) {
  return new THREE.MeshStandardMaterial({ color, roughness: .68, metalness: .12, ...options });
}
function emissive(color, intensity = 1.8) {
  return material(color, { emissive: color, emissiveIntensity: intensity, roughness: .35 });
}
function mesh(geometry, mat, x = 0, y = 0, z = 0) {
  const out = new THREE.Mesh(geometry, mat);
  out.position.set(x, y, z);
  out.castShadow = true;
  out.receiveShadow = true;
  return out;
}
function box(w, h, d, mat, x = 0, y = 0, z = 0) {
  return mesh(new THREE.BoxGeometry(w, h, d), mat, x, y, z);
}
function sphere(r, mat, x = 0, y = 0, z = 0, segments = 12) {
  return mesh(new THREE.SphereGeometry(r, segments, Math.max(6, segments / 2)), mat, x, y, z);
}
function cylinder(r1, r2, h, mat, x = 0, y = 0, z = 0, segments = 10) {
  return mesh(new THREE.CylinderGeometry(r1, r2, h, segments), mat, x, y, z);
}
function add(parent, object, rotation = null) {
  parent.add(object);
  if (rotation) object.rotation.set(...rotation);
  return object;
}
function disposeObject(object) {
  object.traverse((child) => {
    child.geometry?.dispose?.();
    if (Array.isArray(child.material)) child.material.forEach((m) => m.dispose?.());
    else child.material?.dispose?.();
    child.material?.map?.dispose?.();
  });
  object.removeFromParent();
}
function makeLabel(text, color = '#ece9ff', size = 28) {
  const canvas = document.createElement('canvas');
  const ctx = canvas.getContext('2d');
  ctx.font = `700 ${size}px ui-monospace, monospace`;
  const width = Math.ceil(ctx.measureText(text).width + 28);
  canvas.width = Math.max(128, width);
  canvas.height = 52;
  ctx.fillStyle = 'rgba(8,6,16,.84)';
  ctx.fillRect(0, 5, canvas.width, 42);
  ctx.strokeStyle = color;
  ctx.lineWidth = 2;
  ctx.strokeRect(2, 7, canvas.width - 4, 38);
  ctx.font = `700 ${size}px ui-monospace, monospace`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = color;
  ctx.fillText(text, canvas.width / 2, 27);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: texture, transparent: true, depthTest: false }));
  sprite.scale.set(canvas.width / 85, .72, 1);
  sprite.renderOrder = 50;
  return sprite;
}

function buildRoom() {
  const room = new THREE.Group();
  const floor = add(room, mesh(new THREE.PlaneGeometry(24, 19), material(COLORS.floor), 0, 0, 0), [-Math.PI / 2, 0, 0]);
  floor.receiveShadow = true;
  add(room, box(24, 8, .35, material(COLORS.wall), 0, 4, -9.4));
  add(room, box(.35, 8, 19, material(0x181024), -12, 4, 0));
  const grid = new THREE.GridHelper(24, 24, COLORS.purple, 0x302240);
  grid.position.y = .012;
  grid.material.opacity = .23;
  grid.material.transparent = true;
  room.add(grid);
  for (let x = -10; x <= 10; x += 5) {
    add(room, box(3.2, 2.1, .12, material(0x10152c), x, 4.8, -9.18));
    add(room, box(2.8, .07, .08, emissive(COLORS.cyan, 2.2), x, 4.8, -9.08));
  }
  add(room, box(23, .09, .12, emissive(COLORS.pink, 2.5), 0, 7.2, -9.1));
  add(room, box(.1, .08, 18, emissive(COLORS.cyan, 2.3), -11.75, .12, 0));
  const sign = makeLabel('☤  HERMES 3D OFFICE', '#f4c85f', 32);
  sign.position.set(0, 6.2, -9.0);
  sign.scale.multiplyScalar(1.25);
  room.add(sign);
  // Door and server rack.
  add(room, box(2.3, 4.4, .25, material(0x37202d), -9.8, 2.2, -9.03));
  add(room, box(1.7, 3.4, 1.1, material(0x13131c, { metalness: .55 }), -10.3, 1.7, 5.8));
  for (let y = .5; y < 3.1; y += .55) add(room, box(1.25, .08, .06, emissive(y % 1 > .4 ? COLORS.green : COLORS.cyan), -10.3, y, 6.38));
  // Plants.
  for (const [x, z] of [[-10.5, -6.6], [6.5, -7.4]]) {
    add(room, cylinder(.55, .42, .8, material(0x5c352a), x, .4, z));
    for (let i = 0; i < 5; i += 1) {
      const leaf = add(room, mesh(new THREE.ConeGeometry(.35, 1.4, 6), material(i % 2 ? 0x25a66b : 0x1e7d56), x, 1.2, z));
      leaf.rotation.z = (i - 2) * .35;
      leaf.rotation.y = i * 1.2;
    }
  }
  scene.add(room);
  return room;
}

function buildLounge() {
  const lounge = new THREE.Group();
  lounge.position.set(8.1, 0, 4.8);
  add(lounge, box(6.3, .12, 4.2, material(0x2a193d), 0, .06, 0));
  add(lounge, box(5.2, .75, 1.5, material(0x49305f), .3, .55, 1.0));
  add(lounge, box(5.2, 1.35, .55, material(0x5b3b74), .3, 1.15, 1.55));
  add(lounge, box(.65, 1.1, 1.7, material(0x3e2950), -2.55, .72, 1.0));
  add(lounge, box(.65, 1.1, 1.7, material(0x3e2950), 3.15, .72, 1.0));
  add(lounge, cylinder(1.05, 1.05, .15, material(0x68403a), -1.3, .62, -1.0), [0, 0, 0]);
  add(lounge, cylinder(.12, .12, .6, material(0x28222e), -1.3, .3, -1.0));
  const rim = add(lounge, new THREE.Mesh(new THREE.TorusGeometry(3.25, .04, 6, 50), emissive(COLORS.purple, 2)));
  rim.rotation.x = Math.PI / 2;
  rim.position.y = .16;
  scene.add(lounge);
}

function buildDesk(index, seat) {
  const group = new THREE.Group();
  group.position.set(seat.x, 0, seat.z);
  const top = add(group, box(3.7, .22, 1.65, material(COLORS.wood), 0, 1.35, 0));
  add(group, box(.18, 1.3, .18, material(0x251922), -1.55, .65, -.55));
  add(group, box(.18, 1.3, .18, material(0x251922), 1.55, .65, -.55));
  add(group, box(.18, 1.3, .18, material(0x251922), -1.55, .65, .55));
  add(group, box(.18, 1.3, .18, material(0x251922), 1.55, .65, .55));
  const monitorFrame = add(group, box(1.65, 1.05, .18, material(0x0b0b12, { metalness: .5 }), .65, 2.15, -.43));
  const screenMat = emissive(COLORS.green, 1.5);
  const screen = add(group, box(1.38, .76, .04, screenMat, .65, 2.15, -.325));
  add(group, box(.12, .55, .12, material(0x30303c), .65, 1.63, -.43));
  add(group, box(.78, .05, .48, material(0x242330), -.55, 1.5, .12));
  const pad = add(group, box(.7, .025, .85, emissive(index % 2 ? COLORS.purple : COLORS.cyan, .8), -.55, 1.49, .1));
  scene.add(group);
  return { group, screen, screenMat, pad, top };
}

function avatarPart(parent, object, agentId) {
  object.userData.agentId = agentId;
  hitMeshes.push(object);
  return add(parent, object);
}
function buildEmployee(agent, index, seat) {
  const h = hash(agent.id);
  const root = new THREE.Group();
  root.position.set(seat.x - .55, 0, seat.z + .35);
  const body = new THREE.Group();
  root.add(body);
  const skin = material(SKINS[h % SKINS.length]);
  const shirt = material(SHIRTS[(h >> 3) % SHIRTS.length]);
  const hair = material(HAIRS[(h >> 6) % HAIRS.length]);
  avatarPart(body, cylinder(.47, .58, 1.25, shirt, 0, 1.65, 0), agent.id);
  avatarPart(body, sphere(.48, skin, 0, 2.65, 0, 10), agent.id);
  avatarPart(body, sphere(.5, hair, 0, 2.9, -.06, 9), agent.id).scale.set(1.02, .55, 1.02);
  const leftArm = avatarPart(body, cylinder(.12, .13, .95, skin, -.58, 1.78, .05, 8), agent.id);
  const rightArm = avatarPart(body, cylinder(.12, .13, .95, skin, .58, 1.78, .05, 8), agent.id);
  leftArm.rotation.z = -.25; rightArm.rotation.z = .25;
  avatarPart(body, cylinder(.16, .13, 1.05, material(0x20202b), -.26, .62, 0, 8), agent.id);
  avatarPart(body, cylinder(.16, .13, 1.05, material(0x20202b), .26, .62, 0, 8), agent.id);
  if (agent.kind === 'subagent') add(body, new THREE.Mesh(new THREE.TorusGeometry(.43, .055, 6, 18), emissive(COLORS.gold, 1.5))).position.y = 2.12;
  const label = makeLabel(agent.label.slice(0, 18), agent.kind === 'subagent' ? '#f4c85f' : '#d9d4f2', 23);
  label.position.set(0, 4.1, 0);
  root.add(label);
  const status = makeLabel(agent.status.toUpperCase(), '#25e58a', 20);
  status.position.set(0, 3.52, 0);
  status.scale.multiplyScalar(.76);
  root.add(status);
  scene.add(root);
  const desk = buildDesk(index, seat);
  return { agent, root, body, leftArm, rightArm, label, status, desk, target: new THREE.Vector3(seat.x - .55, 0, seat.z + .35), baseY: 0, hit: 0 };
}

function buildTeknium() {
  const root = new THREE.Group();
  const jacket = material(0x17452e);
  const skin = material(0xe0ac69);
  add(root, cylinder(.56, .69, 1.55, jacket, 0, 1.65, 0));
  add(root, sphere(.53, skin, 0, 2.78, 0, 12));
  const visor = add(root, box(1.12, .27, .12, emissive(COLORS.red, 2.5), 0, 2.83, .48));
  visor.rotation.z = -.08;
  for (let i = 0; i < 8; i += 1) {
    const spike = add(root, mesh(new THREE.ConeGeometry(.22, 1.15, 6), material(i % 2 ? 0x18ec83 : 0x079b63), 0, 3.48, 0));
    spike.rotation.z = (i - 3.5) * .17;
    spike.rotation.y = i * .82;
    spike.position.x = (i - 3.5) * .13;
  }
  const leftArm = add(root, cylinder(.14, .16, 1.15, jacket, -.68, 1.8, 0, 8));
  const rightArm = add(root, cylinder(.14, .16, 1.15, jacket, .68, 1.8, 0, 8));
  leftArm.rotation.z = -.3; rightArm.rotation.z = .3;
  add(root, cylinder(.18, .15, 1.25, material(0x17202a), -.3, .55, 0, 8));
  add(root, cylinder(.18, .15, 1.25, material(0x17202a), .3, .55, 0, 8));
  const label = makeLabel('TEKNIUM · MANAGEMENT', '#25e58a', 22);
  label.position.y = 4.45;
  root.add(label);
  root.position.copy(loungeHome);
  scene.add(root);
  root.userData.rightArm = rightArm;
  return root;
}

function buildNousGirl() {
  const root = new THREE.Group();
  const skin = material(0xf0c8a0);
  const white = material(0xdedcea);
  add(root, cylinder(.5, .63, 1.35, white, 0, 1.55, 0));
  add(root, sphere(.5, skin, 0, 2.6, 0, 12));
  add(root, sphere(.57, material(0x21152f), 0, 2.8, -.04, 14)).scale.set(1.05, 1.15, .9);
  add(root, new THREE.Mesh(new THREE.TorusGeometry(.58, .09, 8, 20), emissive(COLORS.purple, 1.6)), [0, 0, 0]).position.y = 2.72;
  add(root, box(.52, .48, .1, material(0x15121d), 0, 1.72, .58));
  add(root, cylinder(.12, .14, .9, skin, -.58, 1.65, .12, 8)).rotation.z = -.45;
  add(root, cylinder(.12, .14, .9, skin, .58, 1.65, .12, 8)).rotation.z = .45;
  add(root, cylinder(.15, .13, .9, material(0x241a30), -.25, .58, .25, 8)).rotation.x = Math.PI / 2.8;
  add(root, cylinder(.15, .13, .9, material(0x241a30), .25, .58, .25, 8)).rotation.x = Math.PI / 2.8;
  const cup = add(root, cylinder(.17, .15, .42, material(0xece9ff), -.84, 1.8, .38, 10));
  add(root, new THREE.Mesh(new THREE.TorusGeometry(.18, .04, 6, 12), material(0xece9ff))).position.set(-1.0, 1.82, .38);
  const label = makeLabel('NOUS GIRL · UNBOTHERED', '#bda7ff', 22);
  label.position.y = 4.25;
  root.add(label);
  root.position.set(9.25, .65, 5.45);
  root.rotation.y = -.45;
  scene.add(root);
  root.userData.cup = cup;
  return root;
}

function initScene() {
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance', alpha: false });
  } catch (error) {
    throw new Error(`WebGL could not start: ${error.message}`);
  }
  scene = new THREE.Scene();
  scene.background = new THREE.Color(COLORS.ink);
  scene.fog = new THREE.FogExp2(COLORS.ink, .025);
  camera = new THREE.PerspectiveCamera(38, 1, .1, 100);
  stage.appendChild(renderer.domElement);
  renderer.domElement.id = 'world';
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.24;
  const ambient = new THREE.HemisphereLight(0xbcb1ff, 0x25142d, 2.5);
  scene.add(ambient);
  const key = new THREE.DirectionalLight(0xffe7cc, 3.5);
  key.position.set(5, 13, 8);
  key.castShadow = true;
  key.shadow.mapSize.set(1024, 1024);
  scene.add(key);
  const purple = new THREE.PointLight(COLORS.purple, 35, 22, 2);
  purple.position.set(8, 5, 4); scene.add(purple);
  const cyan = new THREE.PointLight(COLORS.cyan, 28, 20, 2);
  cyan.position.set(-8, 4, -5); scene.add(cyan);
  buildRoom(); buildLounge();
  teknium = buildTeknium();
  nousGirl = buildNousGirl();
  addStars();
  resize(); updateCamera();
  renderer.setAnimationLoop(frameLoop);
  window.__office3d = { ready: true, renderer: 'WebGL', version: '0.7.0', agents: 0, fps: 0, drawCalls: 0, triangles: 0, patrol: 'home' };
  modeEl.textContent = '3D · LIVE';
}

function addStars() {
  const positions = [];
  for (let i = 0; i < 90; i += 1) positions.push((Math.random() - .5) * 24, .08 + Math.random() * .05, (Math.random() - .5) * 18);
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
  const points = new THREE.Points(geometry, new THREE.PointsMaterial({ color: COLORS.purple, size: .035, transparent: true, opacity: .65 }));
  scene.add(points);
}

function resize() {
  if (!renderer || !camera) return;
  const width = Math.max(1, stage.clientWidth);
  const height = Math.max(1, stage.clientHeight);
  const quality = qualityProfile({ width, height, dpr: window.devicePixelRatio || 1 });
  renderer.setPixelRatio(quality.pixelRatio);
  renderer.setSize(width, height, false);
  renderer.shadowMap.enabled = quality.shadows;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  camera.aspect = width / height;
  camera.updateProjectionMatrix();
  window.__office3d && Object.assign(window.__office3d, quality, { width, height });
}
function updateCamera() {
  const target = new THREE.Vector3(0, 1.8, .45);
  camera.position.set(
    target.x + Math.cos(yaw) * Math.cos(pitch) * distance,
    target.y + Math.sin(pitch) * distance,
    target.z + Math.sin(yaw) * Math.cos(pitch) * distance,
  );
  camera.lookAt(target);
}

function reconcile(rawAgents) {
  agents = rawAgents.map(normalizeAgent);
  const seats = layoutAgents(agents.length);
  const seen = new Set();
  agents.forEach((agent, index) => {
    seen.add(agent.id);
    let record = agentObjects.get(agent.id);
    if (!record) {
      record = buildEmployee(agent, index, seats[index]);
      agentObjects.set(agent.id, record);
    }
    record.agent = agent;
    record.target.set(seats[index].x - .55, 0, seats[index].z + .35);
    record.desk.group.position.set(seats[index].x, 0, seats[index].z);
    updateAgentDisplay(record);
  });
  for (const [id, record] of agentObjects) {
    if (!seen.has(id)) {
      hitMeshes.splice(0, hitMeshes.length, ...hitMeshes.filter((item) => item.userData.agentId !== id));
      disposeObject(record.root); disposeObject(record.desk.group); agentObjects.delete(id);
    }
  }
  countEl.textContent = `${agents.length} agent${agents.length === 1 ? '' : 's'}`;
  window.__office3d && (window.__office3d.agents = agents.length);
}
function updateAgentDisplay(record) {
  const { agent, desk } = record;
  const colors = { running: COLORS.green, typing: COLORS.green, browsing: COLORS.cyan, reading: COLORS.gold, delegating: COLORS.purple, working: COLORS.green, idle: 0x3d3650 };
  const col = colors[agent.activity] || (agent.status === 'waiting' ? COLORS.red : 0x3d3650);
  desk.screenMat.color.setHex(col);
  desk.screenMat.emissive.setHex(col);
  desk.screenMat.emissiveIntensity = agent.status === 'waiting' ? 3 : 1.7;
  record.status.material.map.dispose();
  record.status.material.dispose();
  const color = agent.status === 'waiting' ? '#ff5770' : agent.status === 'thinking' ? '#f4c85f' : '#25e58a';
  const replacement = makeLabel((agent.tool || agent.status).slice(0, 17).toUpperCase(), color, 19);
  replacement.position.copy(record.status.position);
  replacement.scale.copy(record.status.scale);
  record.root.remove(record.status);
  record.status = replacement;
  record.root.add(replacement);
}

function sharpCrack() {
  if (!soundOn) return;
  try {
    audioCtx ||= new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const sr = audioCtx.sampleRate, duration = .19;
    const buffer = audioCtx.createBuffer(1, Math.ceil(sr * duration), sr);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i += 1) {
      const t = i / sr;
      data[i] = (Math.random() * 2 - 1) * (Math.exp(-t * 95) + (t > .026 ? Math.exp(-(t - .026) * 140) * .55 : 0));
    }
    const source = audioCtx.createBufferSource();
    const high = audioCtx.createBiquadFilter();
    const gain = audioCtx.createGain();
    source.buffer = buffer; high.type = 'highpass'; high.frequency.value = 1600;
    gain.gain.setValueAtTime(.34, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(.001, audioCtx.currentTime + duration);
    source.connect(high); high.connect(gain); gain.connect(audioCtx.destination); source.start();
  } catch { /* audio remains optional */ }
}
function speak(quip) {
  if (!voiceOn) return;
  try {
    if (voiceAudio) { voiceAudio.pause(); voiceAudio.currentTime = 0; }
    voiceAudio = new Audio(`audio/${quip.audio}.mp3`);
    voiceAudio.volume = .88;
    voiceAudio.play().catch(() => {});
  } catch { /* voice remains optional */ }
}
function primeMedia() {
  try {
    audioCtx ||= new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    const audio = new Audio('audio/bodyless-comedy.mp3');
    audio.muted = true;
    audio.play().then(() => audio.pause()).catch(() => {});
  } catch { /* optional */ }
}
function syncButtons() {
  soundBtn.textContent = soundOn ? '♪ SOUND ON' : '♪ SOUND OFF';
  voiceBtn.textContent = voiceOn ? 'VOICE ON' : 'VOICE OFF';
  whipBtn.textContent = whipArmed ? 'WHIP ARMED' : (whipCount ? `WHIP ×${whipCount}` : 'WHIP');
  soundBtn.classList.toggle('active', soundOn);
  voiceBtn.classList.toggle('active', voiceOn);
  whipBtn.classList.toggle('armed', whipArmed);
}

function createWhip(targetId, sourcePosition, autonomous = false) {
  const record = agentObjects.get(targetId);
  if (!record || activeEffects.some((effect) => effect.kind === 'whip')) return;
  const quip = WHIP_LINES[patrolIndex++ % WHIP_LINES.length];
  const mat = new THREE.MeshStandardMaterial({ color: 0xffd36b, emissive: 0xff9f28, emissiveIntensity: 1.8, roughness: .42 });
  const rope = new THREE.Mesh(new THREE.TubeGeometry(new THREE.LineCurve3(new THREE.Vector3(), new THREE.Vector3(.1, 0, 0)), 4, .07, 8, false), mat);
  scene.add(rope);
  const reaction = makeLabel(quip.bubble, '#ffdd78', 27);
  reaction.visible = false;
  scene.add(reaction);
  const effect = {
    kind: 'whip', targetId, record, start: performance.now() / 1000,
    source: sourcePosition.clone(), rope, reaction, quip, cracked: false, burst: false, autonomous,
  };
  activeEffects.push(effect);
  whipCount += 1;
  syncButtons();
}
function spawnBurst(effect, target) {
  effect.burst = true;
  const profile = qualityProfile({ width: stage.clientWidth, height: stage.clientHeight, dpr: window.devicePixelRatio || 1 });
  for (let i = 0; i < profile.particles; i += 1) {
    const particle = sphere(.045 + Math.random() * .055, emissive(i % 2 ? COLORS.gold : COLORS.pink, 2));
    particle.position.copy(target);
    scene.add(particle);
    activeEffects.push({ kind: 'particle', mesh: particle, born: performance.now() / 1000, velocity: new THREE.Vector3((Math.random() - .5) * 5, 2 + Math.random() * 4, (Math.random() - .5) * 5) });
  }
}
function updateEffects(now, dt) {
  for (let i = activeEffects.length - 1; i >= 0; i -= 1) {
    const effect = activeEffects[i];
    if (effect.kind === 'particle') {
      const age = now - effect.born;
      effect.velocity.y -= 7 * dt;
      effect.mesh.position.addScaledVector(effect.velocity, dt);
      effect.mesh.scale.setScalar(Math.max(.01, 1 - age / .9));
      if (age > .9) { disposeObject(effect.mesh); activeEffects.splice(i, 1); }
      continue;
    }
    const age = now - effect.start;
    const phase = whipPhase(age);
    const target = effect.record.root.position.clone().add(new THREE.Vector3(0, 2.2, 0));
    const source = effect.source.clone().add(new THREE.Vector3(0, 2.3, 0));
    const wind = Math.min(1, age / .2);
    const snap = Math.max(0, Math.min(1, (age - .2) / .24));
    const eased = 1 - (1 - snap) ** 3;
    const end = snap > 0 ? source.clone().lerp(target, eased) : source.clone().add(new THREE.Vector3(-1.2 * wind, 1.4 * wind, 0));
    const wave = age > .43 ? Math.sin((age - .43) * 22) * Math.max(0, 1 - (age - .43) / .65) : 0;
    const points = [
      source,
      source.clone().lerp(end, .33).add(new THREE.Vector3(0, 1.2 * (1 - snap) + wave, 1.4 * (1 - snap))),
      source.clone().lerp(end, .68).add(new THREE.Vector3(0, -.7 * snap - wave, -.8 * (1 - snap))),
      end,
    ];
    effect.rope.geometry.dispose();
    effect.rope.geometry = new THREE.TubeGeometry(new THREE.CatmullRomCurve3(points), 22, .07, 8, false);
    if (age >= .42 && !effect.cracked) {
      effect.cracked = true; sharpCrack(); setTimeout(() => speak(effect.quip), 240); spawnBurst(effect, target);
      effect.record.hit = now;
    }
    effect.reaction.visible = phase === 'impact' || phase === 'reaction';
    effect.reaction.position.copy(target).add(new THREE.Vector3(0, 2.25, 0));
    if (phase === 'done') {
      disposeObject(effect.rope); disposeObject(effect.reaction); activeEffects.splice(i, 1);
    }
  }
}

function animateAgents(now) {
  for (const record of agentObjects.values()) {
    record.root.position.lerp(record.target, .09);
    const activity = record.agent.activity;
    const typing = activity === 'typing' || activity === 'running';
    record.leftArm.rotation.x = typing ? -.7 + Math.sin(now * 13) * .18 : 0;
    record.rightArm.rotation.x = typing ? -.7 - Math.sin(now * 13) * .18 : 0;
    record.body.position.y = Math.sin(now * (record.agent.status === 'working' ? 5 : 2) + hash(record.agent.id)) * .035;
    record.desk.screenMat.emissiveIntensity = 1.4 + Math.sin(now * 7 + hash(record.agent.id)) * .35;
    if (record.hit && now - record.hit < .85) {
      const p = (now - record.hit) / .85;
      record.body.position.y += Math.sin(p * Math.PI) * 1.1;
      record.body.rotation.z = Math.sin(p * Math.PI * 8) * .12;
    } else record.body.rotation.z = 0;
  }
}
function frameLoop() {
  const now = performance.now() / 1000;
  const dt = Math.min(clock.getDelta(), .05);
  animateAgents(now);
  // advancePatrol needs the actual frame delta; clock was consumed above.
  const targets = [...agentObjects.entries()].map(([id, record]) => ({ id, x: record.root.position.x, z: record.root.position.z }));
  const out = advancePatrol(patrol, targets, dt, now, { x: loungeHome.x, z: loungeHome.z });
  patrol = out.state;
  teknium.position.x = patrol.x; teknium.position.z = patrol.z;
  teknium.position.y = Math.abs(Math.sin(now * 7)) * ((patrol.phase === 'patrol' || patrol.phase === 'return') ? .08 : .02);
  const destination = patrol.phase === 'return'
    ? loungeHome
    : targets.find(({ id }) => id === patrol.targetId);
  if (destination && (patrol.phase === 'patrol' || patrol.phase === 'return')) {
    teknium.rotation.y = Math.atan2(destination.x - patrol.x, destination.z - patrol.z);
  } else if (patrol.phase === 'home') teknium.rotation.y = -.45;
  if (out.strikeTargetId) createWhip(out.strikeTargetId, teknium.position, true);
  nousGirl.position.y = .65 + Math.sin(now * 1.8) * .025;
  nousGirl.userData.cup.rotation.z = Math.sin(now * .7) * .08;
  updateEffects(now, dt);
  renderer.render(scene, camera);
  fpsFrames += 1;
  const stamp = performance.now();
  if (stamp - fpsAt >= 1000) {
    fps = Math.round(fpsFrames * 1000 / (stamp - fpsAt)); fpsFrames = 0; fpsAt = stamp;
    if (window.__office3d) Object.assign(window.__office3d, { fps, drawCalls: renderer.info.render.calls, triangles: renderer.info.render.triangles, patrol: patrol.phase, effects: activeEffects.length });
  }
}

function pickAgent(event) {
  const rect = renderer.domElement.getBoundingClientRect();
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);
  const hit = raycaster.intersectObjects(hitMeshes, false)[0];
  return hit?.object?.userData?.agentId || null;
}
function setupInteraction() {
  const canvas = renderer.domElement;
  canvas.addEventListener('pointerdown', (event) => { drag = { x: event.clientX, y: event.clientY, yaw, pitch, moved: false }; canvas.setPointerCapture(event.pointerId); });
  canvas.addEventListener('pointermove', (event) => {
    if (!drag) return;
    const dx = event.clientX - drag.x, dy = event.clientY - drag.y;
    if (Math.hypot(dx, dy) > 4) drag.moved = true;
    if (drag.moved) {
      yaw = drag.yaw - dx * .006;
      pitch = Math.max(.22, Math.min(1.1, drag.pitch + dy * .005));
      updateCamera();
    }
  });
  canvas.addEventListener('pointerup', (event) => {
    const wasDrag = drag?.moved; drag = null;
    if (!wasDrag && whipArmed) {
      const id = pickAgent(event);
      if (id) { primeMedia(); createWhip(id, teknium.position); }
    }
  });
  canvas.addEventListener('wheel', (event) => { event.preventDefault(); distance = Math.max(16, Math.min(38, distance + event.deltaY * .015)); updateCamera(); }, { passive: false });
  window.addEventListener('resize', resize);
}

function applyState(state) {
  reconcile(Array.isArray(state?.agents) ? state.agents : []);
  countEl.classList.remove('offline');
}
async function poll() {
  try { const response = await fetch('state', { cache: 'no-store' }); if (!response.ok) throw new Error(String(response.status)); applyState(await response.json()); }
  catch (error) { countEl.textContent = 'OFFLINE'; countEl.classList.add('offline'); console.warn('[office3d] state unavailable', error); }
  setTimeout(poll, 1500);
}
function setupData() {
  if (IN_VSCODE) {
    window.addEventListener('message', (event) => { if (event.data?.type === 'state') applyState(event.data.state); });
  } else poll();
}

soundBtn.onclick = () => { soundOn = !soundOn; localStorage.setItem('office3dSound', soundOn ? '1' : '0'); primeMedia(); syncButtons(); };
voiceBtn.onclick = () => { voiceOn = !voiceOn; localStorage.setItem('office3dVoice', voiceOn ? '1' : '0'); primeMedia(); syncButtons(); };
whipBtn.onclick = () => { whipArmed = !whipArmed; primeMedia(); syncButtons(); };
resetBtn.onclick = () => { yaw = .62; pitch = .66; distance = 30; updateCamera(); };

document.getElementById('pixel').onclick = () => { window.location.href = 'pixel.html'; };

try {
  initScene(); setupInteraction(); setupData(); syncButtons();
} catch (error) {
  console.error('[office3d] fatal', error);
  errorEl.hidden = false;
  errorEl.querySelector('strong').textContent = '3D renderer unavailable';
  errorEl.querySelector('span').textContent = error.message;
  modeEl.textContent = '3D FAILED';
  window.__office3d = { ready: false, error: error.message };
}
