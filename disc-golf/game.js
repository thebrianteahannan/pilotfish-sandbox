import * as THREE from "three";

const canvas = document.getElementById("stage");
const hands = document.getElementById("hands");
const heldDisc = document.getElementById("held-disc");
const powerMeter = document.getElementById("power-meter");
const powerFill = document.getElementById("power-fill");
const resultEl = document.getElementById("result");
const resultTitle = document.getElementById("result-title");
const resultSub = document.getElementById("result-sub");
const againBtn = document.getElementById("again");
const madeEl = document.getElementById("made");
const missedEl = document.getElementById("missed");

const BASKET_Z = -18;
const BASKET_Y = 1.15;
const CHAIN_RADIUS = 0.42;
const BASKET_HEIGHT = 0.95;
const POLE_TOP = 2.35;

let made = 0;
let missed = 0;
let phase = "ready";
let audioCtx = null;
let discMesh = null;
let basketGroup = null;
let chainMeshes = [];
let chainShake = 0;

const pointer = { id: null, startY: 0, startX: 0, lastY: 0, lastX: 0, lastT: 0, pull: 0, velY: 0, velX: 0 };
const flight = { active: false, pos: new THREE.Vector3(), vel: new THREE.Vector3(), spin: 0, age: 0, hitChains: false };

const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: true,
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;

const scene = new THREE.Scene();
scene.fog = new THREE.Fog(0xa8c9a0, 12, 42);

const camera = new THREE.PerspectiveCamera(
  62,
  window.innerWidth / window.innerHeight,
  0.1,
  80
);
camera.position.set(0, 1.55, 0.2);
camera.lookAt(0, 1.2, BASKET_Z);

scene.add(new THREE.HemisphereLight(0xcfe8ff, 0x3d5c3a, 1.05));
const sun = new THREE.DirectionalLight(0xfff1c9, 1.15);
sun.position.set(6, 14, 4);
sun.castShadow = true;
sun.shadow.mapSize.set(1024, 1024);
scene.add(sun);

function makeTree() {
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.18, 1.4, 6),
    new THREE.MeshStandardMaterial({ color: 0x5a3b28, roughness: 1 })
  );
  trunk.position.y = 0.7;
  trunk.castShadow = true;
  const canopy = new THREE.Mesh(
    new THREE.ConeGeometry(1.1, 2.4, 7),
    new THREE.MeshStandardMaterial({ color: 0x1f4a32, roughness: 0.85 })
  );
  canopy.position.y = 2.3;
  canopy.castShadow = true;
  g.add(trunk, canopy);
  return g;
}

function makeBasket() {
  const g = new THREE.Group();
  g.position.set(0, 0, BASKET_Z);

  const metal = new THREE.MeshStandardMaterial({
    color: 0xc8d0d6,
    metalness: 0.72,
    roughness: 0.35,
  });

  const pole = new THREE.Mesh(
    new THREE.CylinderGeometry(0.05, 0.06, POLE_TOP, 12),
    metal
  );
  pole.position.y = POLE_TOP / 2;
  pole.castShadow = true;
  g.add(pole);

  const topBand = new THREE.Mesh(
    new THREE.TorusGeometry(CHAIN_RADIUS, 0.035, 8, 28),
    metal
  );
  topBand.rotation.x = Math.PI / 2;
  topBand.position.y = BASKET_Y + BASKET_HEIGHT;
  g.add(topBand);

  const botBand = new THREE.Mesh(
    new THREE.TorusGeometry(CHAIN_RADIUS * 0.92, 0.04, 8, 28),
    metal
  );
  botBand.rotation.x = Math.PI / 2;
  botBand.position.y = BASKET_Y;
  g.add(botBand);

  const tray = new THREE.Mesh(
    new THREE.CylinderGeometry(CHAIN_RADIUS * 1.15, CHAIN_RADIUS * 1.25, 0.12, 24, 1, true),
    metal
  );
  tray.position.y = BASKET_Y - 0.05;
  g.add(tray);

  const chainMat = new THREE.MeshStandardMaterial({
    color: 0xd7dde2,
    metalness: 0.85,
    roughness: 0.28,
  });
  chainMeshes = [];
  const strands = 12;
  for (let i = 0; i < strands; i++) {
    const a = (i / strands) * Math.PI * 2;
    const chain = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.012, BASKET_HEIGHT, 5),
      chainMat
    );
    chain.position.set(
      Math.cos(a) * CHAIN_RADIUS * 0.72,
      BASKET_Y + BASKET_HEIGHT / 2,
      Math.sin(a) * CHAIN_RADIUS * 0.72
    );
    chain.userData.baseX = chain.position.x;
    chain.userData.baseZ = chain.position.z;
    g.add(chain);
    chainMeshes.push(chain);
  }

  const number = new THREE.Mesh(
    new THREE.BoxGeometry(0.35, 0.35, 0.04),
    new THREE.MeshStandardMaterial({ color: 0xe8c547, roughness: 0.55 })
  );
  number.position.set(0, BASKET_Y + BASKET_HEIGHT + 0.28, 0);
  g.add(number);

  return g;
}

function makeDisc() {
  const g = new THREE.Group();
  const body = new THREE.Mesh(
    new THREE.CylinderGeometry(0.22, 0.22, 0.035, 32),
    new THREE.MeshStandardMaterial({
      color: 0xe8c547,
      roughness: 0.45,
      metalness: 0.1,
    })
  );
  body.castShadow = true;
  g.add(body);
  const rim = new THREE.Mesh(
    new THREE.TorusGeometry(0.2, 0.018, 8, 32),
    new THREE.MeshStandardMaterial({ color: 0xc9a12a, roughness: 0.4 })
  );
  rim.rotation.x = Math.PI / 2;
  g.add(rim);
  g.visible = false;
  return g;
}

function buildCourse() {
  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(80, 80),
    new THREE.MeshStandardMaterial({ color: 0x2f5c3f, roughness: 0.95 })
  );
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  const fairway = new THREE.Mesh(
    new THREE.PlaneGeometry(5.2, 28),
    new THREE.MeshStandardMaterial({ color: 0x3d7a52, roughness: 0.9 })
  );
  fairway.rotation.x = -Math.PI / 2;
  fairway.position.set(0, 0.01, -12);
  fairway.receiveShadow = true;
  scene.add(fairway);

  for (let i = 0; i < 18; i++) {
    const tree = makeTree();
    const side = i % 2 === 0 ? -1 : 1;
    tree.position.set(
      side * (3.8 + Math.random() * 5),
      0,
      -4 - Math.random() * 24
    );
    tree.scale.setScalar(0.75 + Math.random() * 0.55);
    scene.add(tree);
  }

  basketGroup = makeBasket();
  scene.add(basketGroup);
  discMesh = makeDisc();
  scene.add(discMesh);
}

function ensureAudio() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
  if (audioCtx.state === "suspended") audioCtx.resume();
}

function playChainRattle() {
  ensureAudio();
  const now = audioCtx.currentTime;
  for (let i = 0; i < 10; i++) {
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    const filter = audioCtx.createBiquadFilter();
    osc.type = i % 2 === 0 ? "triangle" : "square";
    osc.frequency.value = 700 + Math.random() * 1400;
    filter.type = "bandpass";
    filter.frequency.value = 1800 + Math.random() * 2200;
    filter.Q.value = 4;
    const t0 = now + i * 0.018;
    gain.gain.setValueAtTime(0.0001, t0);
    gain.gain.exponentialRampToValueAtTime(0.12 - i * 0.008, t0 + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.12 + Math.random() * 0.08);
    osc.connect(filter);
    filter.connect(gain);
    gain.connect(audioCtx.destination);
    osc.start(t0);
    osc.stop(t0 + 0.22);
  }
  const noiseBuf = audioCtx.createBuffer(1, audioCtx.sampleRate * 0.25, audioCtx.sampleRate);
  const data = noiseBuf.getChannelData(0);
  for (let i = 0; i < data.length; i++) {
    data[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / data.length, 2.2);
  }
  const noise = audioCtx.createBufferSource();
  noise.buffer = noiseBuf;
  const ng = audioCtx.createGain();
  ng.gain.value = 0.18;
  const nf = audioCtx.createBiquadFilter();
  nf.type = "highpass";
  nf.frequency.value = 1200;
  noise.connect(nf);
  nf.connect(ng);
  ng.connect(audioCtx.destination);
  noise.start(now);
}

function playWhoosh(power) {
  ensureAudio();
  const now = audioCtx.currentTime;
  const buf = audioCtx.createBuffer(1, audioCtx.sampleRate * 0.28, audioCtx.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * Math.sin((i / data.length) * Math.PI) * 0.35;
  const src = audioCtx.createBufferSource();
  src.buffer = buf;
  const filter = audioCtx.createBiquadFilter();
  filter.type = "bandpass";
  filter.frequency.setValueAtTime(400, now);
  filter.frequency.exponentialRampToValueAtTime(1800 + power * 900, now + 0.2);
  const gain = audioCtx.createGain();
  gain.gain.value = 0.15 + power * 0.12;
  src.connect(filter); filter.connect(gain); gain.connect(audioCtx.destination);
  src.start(now);
}

const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

function setAimVisual(pull, lateral) {
  const p = clamp(pull, 0, 1);
  const y = p * 42;
  const x = lateral * 18;
  hands.style.transform = `translate(${x}px, ${y}px) scale(${1 - p * 0.08})`;
  heldDisc.style.transform = `translateX(calc(-50% + ${x * 0.4}px)) translateY(${y * 0.35}px) rotate(${-4 + lateral * 12}deg)`;
  powerMeter.hidden = p < 0.02;
  powerFill.style.width = `${Math.round(p * 100)}%`;
  document.body.classList.toggle("aiming", p > 0.02);
}

function resetThrow() {
  phase = "ready";
  flight.active = false;
  flight.hitChains = false;
  discMesh.visible = false;
  pointer.pull = 0;
  setAimVisual(0, 0);
  powerMeter.hidden = true;
  document.body.classList.remove("flying", "aiming");
  canvas.classList.remove("throwing");
  resultEl.hidden = true;
  resultEl.classList.remove("made", "missed");
  camera.position.set(0, 1.55, 0.2);
  camera.lookAt(0, 1.2, BASKET_Z);
}

function showResult(isMade) {
  phase = "settled";
  resultEl.hidden = false;
  if (isMade) {
    made += 1;
    madeEl.textContent = String(made);
    resultEl.classList.add("made");
    resultTitle.textContent = "Chain in!";
    resultSub.textContent = "The disc settled in the basket.";
  } else {
    missed += 1;
    missedEl.textContent = String(missed);
    resultEl.classList.add("missed");
    resultTitle.textContent = "Miss";
    resultSub.textContent = flight.hitChains
      ? "Hit the chains, but spit out."
      : "Wide of the pin. Try again.";
  }
}

function launchDisc() {
  const pull = clamp(pointer.pull, 0, 1);
  const forwardSpeed = clamp(-pointer.velY, 0.2, 3.8);
  const power = clamp(pull * 0.55 + forwardSpeed * 0.35, 0.15, 1);
  const lateral = clamp(pointer.velX * 0.08 + (pointer.lastX - pointer.startX) * 0.0015, -1.2, 1.2);

  if (forwardSpeed < 0.25 && pull < 0.18) {
    setAimVisual(0, 0);
    phase = "ready";
    canvas.classList.remove("throwing");
    return;
  }

  playWhoosh(power);
  phase = "flying";
  document.body.classList.add("flying");
  canvas.classList.remove("throwing");
  setAimVisual(0, 0);
  powerMeter.hidden = true;

  flight.active = true;
  flight.age = 0;
  flight.hitChains = false;
  flight.pos.set(0.05, 1.35, -0.35);
  flight.vel.set(lateral * 3.2, 1.1 + power * 2.4, -(9 + power * 14));
  flight.spin = 10 + power * 16;
  discMesh.visible = true;
  discMesh.position.copy(flight.pos);
}

function discInChains(pos) {
  const radial = Math.hypot(pos.x - basketGroup.position.x, pos.z - basketGroup.position.z);
  return pos.y > BASKET_Y - 0.05 && pos.y < BASKET_Y + BASKET_HEIGHT + 0.15 && radial < CHAIN_RADIUS * 0.95;
}

function updateFlight(dt) {
  if (!flight.active) return;

  flight.age += dt;
  flight.vel.y -= 9.2 * dt;
  flight.vel.x += -flight.spin * 0.012 * dt;
  flight.vel.z *= 1 - 0.08 * dt;
  flight.pos.addScaledVector(flight.vel, dt);
  discMesh.position.copy(flight.pos);
  discMesh.rotation.y += flight.spin * dt;
  discMesh.rotation.x = -0.35;
  discMesh.rotation.z = clamp(flight.vel.x * 0.08, -0.5, 0.5);

  camera.position.lerp(
    new THREE.Vector3(flight.pos.x * 0.15, 1.55 + flight.pos.y * 0.05, 0.2 + flight.pos.z * 0.02),
    0.08
  );
  camera.lookAt(flight.pos.x, flight.pos.y, flight.pos.z);

  if (!flight.hitChains && discInChains(flight.pos)) {
    flight.hitChains = true;
    chainShake = 1;
    playChainRattle();
    flight.vel.multiplyScalar(0.22);
    flight.vel.x *= 0.2;
    flight.vel.z *= 0.15;
    flight.vel.y = Math.min(flight.vel.y, 0.4);
  }

  if (flight.hitChains && flight.pos.y <= BASKET_Y + 0.08 && Math.hypot(flight.pos.x, flight.pos.z - BASKET_Z) < CHAIN_RADIUS * 0.7) {
    flight.active = false;
    flight.pos.y = BASKET_Y + 0.06;
    discMesh.position.copy(flight.pos);
    showResult(true);
    return;
  }

  if (flight.pos.y <= 0.04) {
    flight.pos.y = 0.04;
    flight.active = false;
    const nearBasket = Math.hypot(flight.pos.x, flight.pos.z - BASKET_Z) < 1.1;
    showResult(nearBasket && flight.hitChains);
    return;
  }

  if (flight.age > 5 || flight.pos.z < BASKET_Z - 6 || Math.abs(flight.pos.x) > 12) {
    flight.active = false;
    showResult(false);
  }
}

function updateChains(dt) {
  if (chainShake <= 0) return;
  chainShake = Math.max(0, chainShake - dt * 2.2);
  for (let i = 0; i < chainMeshes.length; i++) {
    const c = chainMeshes[i];
    const wobble = Math.sin(performance.now() * 0.04 + i) * chainShake * 0.05;
    c.position.x = c.userData.baseX + wobble;
    c.position.z = c.userData.baseZ + wobble * 0.7;
  }
}

function onPointerDown(e) {
  if (phase !== "ready") return;
  ensureAudio();
  pointer.id = e.pointerId;
  pointer.startY = e.clientY;
  pointer.startX = e.clientX;
  pointer.lastY = e.clientY;
  pointer.lastX = e.clientX;
  pointer.lastT = performance.now();
  pointer.pull = 0;
  pointer.velY = 0;
  pointer.velX = 0;
  phase = "aiming";
  canvas.classList.add("throwing");
  canvas.setPointerCapture?.(e.pointerId);
}

function onPointerMove(e) {
  if (phase !== "aiming" || e.pointerId !== pointer.id) return;
  const now = performance.now();
  const dt = Math.max(8, now - pointer.lastT);
  const dy = e.clientY - pointer.lastY;
  const dx = e.clientX - pointer.lastX;
  pointer.velY = (dy / dt) * 16;
  pointer.velX = (dx / dt) * 16;
  pointer.lastY = e.clientY;
  pointer.lastX = e.clientX;
  pointer.lastT = now;

  const pullPx = e.clientY - pointer.startY;
  pointer.pull = clamp(pullPx / (window.innerHeight * 0.35), 0, 1);
  const lateral = clamp((e.clientX - pointer.startX) / (window.innerWidth * 0.4), -1, 1);
  setAimVisual(pointer.pull, lateral);
}

function onPointerUp(e) {
  if (phase !== "aiming" || e.pointerId !== pointer.id) return;
  pointer.id = null;
  launchDisc();
}

canvas.addEventListener("pointerdown", onPointerDown);
canvas.addEventListener("pointermove", onPointerMove);
canvas.addEventListener("pointerup", onPointerUp);
canvas.addEventListener("pointercancel", onPointerUp);
againBtn.addEventListener("click", resetThrow);

window.addEventListener("resize", () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

buildCourse();

let last = performance.now();
function tick(now) {
  const dt = Math.min(0.033, (now - last) / 1000);
  last = now;
  updateFlight(dt);
  updateChains(dt);
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
requestAnimationFrame(tick);
