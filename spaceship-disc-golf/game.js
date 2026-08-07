import * as THREE from "three";

const canvas = document.getElementById("c");
const scoreEl = document.getElementById("score");
const holeEl = document.getElementById("hole");
const toastEl = document.getElementById("toast");
const startScreen = document.getElementById("start-screen");
const startBtn = document.getElementById("start-btn");
const throwBtn = document.getElementById("throw-btn");

const HOLES = 5;
const keys = new Set();
let score = 0;
let holeIndex = 0;
let playing = false;
let yaw = 0;
let pitch = 0;
let pointerDown = false;
let lastX = 0;
let lastY = 0;
let cooldown = 0;
let toastTimer = 0;

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;

const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x0b1530, 0.0045);
scene.background = new THREE.Color(0x070b14);

const camera = new THREE.PerspectiveCamera(70, innerWidth / innerHeight, 0.1, 2000);
const ship = new THREE.Group();
ship.position.set(0, 40, 120);
scene.add(ship);

function makeShip() {
  const body = new THREE.Mesh(
    new THREE.ConeGeometry(1.2, 4.2, 6),
    new THREE.MeshStandardMaterial({ color: 0x3de0ff, metalness: 0.7, roughness: 0.35, emissive: 0x0a3a4a })
  );
  body.rotation.x = Math.PI / 2;
  const wing = new THREE.Mesh(
    new THREE.BoxGeometry(5.5, 0.15, 1.6),
    new THREE.MeshStandardMaterial({ color: 0xff4d9a, metalness: 0.5, roughness: 0.4 })
  );
  wing.position.z = 0.6;
  const glow = new THREE.PointLight(0x3de0ff, 2.2, 28);
  glow.position.set(0, 0, 1.2);
  ship.add(body, wing, glow);
}
makeShip();

scene.add(new THREE.AmbientLight(0x6688aa, 0.55));
const sun = new THREE.DirectionalLight(0xffe0b0, 1.35);
sun.position.set(80, 140, 40);
scene.add(sun);
const rim = new THREE.DirectionalLight(0x6a4dff, 0.55);
rim.position.set(-60, 40, -80);
scene.add(rim);

// Stars
{
  const count = 900;
  const pos = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    pos[i * 3] = (Math.random() - 0.5) * 1600;
    pos[i * 3 + 1] = Math.random() * 600 + 80;
    pos[i * 3 + 2] = (Math.random() - 0.5) * 1600;
  }
  const geo = new THREE.BufferGeometry();
  geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
  scene.add(new THREE.Points(geo, new THREE.PointsMaterial({ color: 0xffffff, size: 1.2, sizeAttenuation: true })));
}

// Terrain
const ground = new THREE.Mesh(
  new THREE.PlaneGeometry(900, 900, 96, 96),
  new THREE.MeshStandardMaterial({ color: 0x1c3d2a, roughness: 0.95, flatShading: true })
);
ground.rotation.x = -Math.PI / 2;
const gPos = ground.geometry.attributes.position;
for (let i = 0; i < gPos.count; i++) {
  const x = gPos.getX(i);
  const y = gPos.getY(i);
  const h =
    Math.sin(x * 0.02) * Math.cos(y * 0.018) * 8 +
    Math.sin(x * 0.05 + y * 0.03) * 4;
  gPos.setZ(i, h);
}
gPos.needsUpdate = true;
ground.geometry.computeVertexNormals();
scene.add(ground);

const mountains = [];
const baskets = [];
const discs = [];

function mountainMesh(radius, height, color) {
  const mesh = new THREE.Mesh(
    new THREE.ConeGeometry(radius, height, 7),
    new THREE.MeshStandardMaterial({ color, roughness: 0.9, flatShading: true })
  );
  mesh.castShadow = true;
  return mesh;
}

function makeBasket() {
  const g = new THREE.Group();
  const pole = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.18, 3.2, 8),
    new THREE.MeshStandardMaterial({ color: 0xcccccc, metalness: 0.8, roughness: 0.3 })
  );
  pole.position.y = 1.6;
  const band = new THREE.Mesh(
    new THREE.TorusGeometry(0.85, 0.08, 8, 24),
    new THREE.MeshStandardMaterial({ color: 0xffb347, emissive: 0x553300, metalness: 0.6 })
  );
  band.position.y = 2.7;
  band.rotation.x = Math.PI / 2;
  const chains = new THREE.Group();
  for (let i = 0; i < 10; i++) {
    const a = (i / 10) * Math.PI * 2;
    const link = new THREE.Mesh(
      new THREE.CylinderGeometry(0.03, 0.03, 1.1, 4),
      new THREE.MeshStandardMaterial({ color: 0xdddddd, metalness: 0.9, roughness: 0.25 })
    );
    link.position.set(Math.cos(a) * 0.55, 2.15, Math.sin(a) * 0.55);
    link.rotation.z = Math.sin(a) * 0.35;
    link.rotation.x = Math.cos(a) * 0.35;
    chains.add(link);
  }
  const beacon = new THREE.PointLight(0xffb347, 1.4, 40);
  beacon.position.y = 3.2;
  g.add(pole, band, chains, beacon);
  g.userData = { radius: 1.35 };
  return g;
}

function layoutCourse() {
  mountains.forEach((m) => scene.remove(m));
  baskets.forEach((b) => scene.remove(b));
  mountains.length = 0;
  baskets.length = 0;

  const layouts = [
    { x: -40, z: -60, r: 28, h: 55, c: 0x3a4a3a },
    { x: 55, z: -110, r: 34, h: 72, c: 0x455545 },
    { x: -90, z: -150, r: 40, h: 88, c: 0x2f4038 },
    { x: 20, z: -210, r: 36, h: 78, c: 0x4a5a48 },
    { x: -30, z: -280, r: 46, h: 96, c: 0x364636 },
  ];

  layouts.forEach((L, i) => {
    const m = mountainMesh(L.r, L.h, L.c);
    m.position.set(L.x, L.h / 2 - 2, L.z);
    scene.add(m);
    mountains.push(m);

    const basket = makeBasket();
    basket.position.set(L.x, L.h - 1.5, L.z);
    basket.userData.active = i === holeIndex;
    basket.userData.index = i;
    scene.add(basket);
    baskets.push(basket);

    // snow cap
    const cap = new THREE.Mesh(
      new THREE.ConeGeometry(L.r * 0.35, L.h * 0.18, 7),
      new THREE.MeshStandardMaterial({ color: 0xe8f4ff, roughness: 0.7 })
    );
    cap.position.set(L.x, L.h * 0.82, L.z);
    scene.add(cap);
    mountains.push(cap);
  });
  updateHoleHud();
}

function updateHoleHud() {
  holeEl.textContent = `${Math.min(holeIndex + 1, HOLES)} / ${HOLES}`;
  baskets.forEach((b, i) => {
    b.userData.active = i === holeIndex;
    const light = b.children.find((c) => c.isLight);
    if (light) light.intensity = b.userData.active ? 2.4 : 0.5;
  });
}

function showToast(msg) {
  toastEl.hidden = false;
  toastEl.textContent = msg;
  toastTimer = 1.6;
}

function throwDisc() {
  if (!playing || cooldown > 0) return;
  cooldown = 0.35;
  const dir = new THREE.Vector3(0, 0, -1)
    .applyEuler(new THREE.Euler(pitch, yaw, 0, "YXZ"))
    .normalize();
  const disc = new THREE.Mesh(
    new THREE.CylinderGeometry(0.55, 0.55, 0.08, 24),
    new THREE.MeshStandardMaterial({
      color: 0xff4d9a,
      emissive: 0x551133,
      metalness: 0.4,
      roughness: 0.35,
    })
  );
  disc.position.copy(ship.position).add(dir.clone().multiplyScalar(3));
  disc.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir);
  disc.userData = {
    vel: dir.multiplyScalar(55),
    life: 8,
    spin: 18,
  };
  scene.add(disc);
  discs.push(disc);
}

function advanceHole() {
  score += 100;
  scoreEl.textContent = String(score);
  holeIndex += 1;
  if (holeIndex >= HOLES) {
    showToast("Course complete!");
    holeIndex = HOLES - 1;
    updateHoleHud();
    return;
  }
  showToast(`Chain in! Hole ${holeIndex + 1}`);
  updateHoleHud();
}

const clock = new THREE.Clock();

function update(dt) {
  if (!playing) return;
  cooldown = Math.max(0, cooldown - dt);
  if (toastTimer > 0) {
    toastTimer -= dt;
    if (toastTimer <= 0) toastEl.hidden = true;
  }

  const turn = (keys.has("a") || keys.has("arrowleft") ? 1 : 0) - (keys.has("d") || keys.has("arrowright") ? 1 : 0);
  const climb = (keys.has("r") || keys.has("arrowup") ? 1 : 0) - (keys.has("f") || keys.has("arrowdown") ? 1 : 0);
  const throttle = (keys.has("w") ? 1 : 0) - (keys.has("s") ? 1 : 0);
  const roll = (keys.has("q") ? 1 : 0) - (keys.has("e") ? 1 : 0);

  yaw += turn * 1.6 * dt;
  pitch = THREE.MathUtils.clamp(pitch + climb * 1.2 * dt, -1.1, 1.1);

  const forward = new THREE.Vector3(0, 0, -1).applyEuler(new THREE.Euler(pitch, yaw, 0, "YXZ"));
  const speed = 28 + throttle * 38;
  ship.position.addScaledVector(forward, speed * dt);
  ship.position.y = THREE.MathUtils.clamp(ship.position.y + climb * 22 * dt, 8, 160);
  ship.rotation.set(pitch * 0.85, yaw, roll * 0.5, "YXZ");

  // camera chase
  const camOffset = new THREE.Vector3(0, 3.5, 10).applyEuler(new THREE.Euler(pitch * 0.6, yaw, 0, "YXZ"));
  camera.position.lerp(ship.position.clone().add(camOffset), 1 - Math.pow(0.001, dt));
  camera.lookAt(ship.position.clone().add(forward.multiplyScalar(12)));

  for (let i = discs.length - 1; i >= 0; i--) {
    const d = discs[i];
    d.userData.life -= dt;
    d.userData.vel.y -= 6 * dt; // gentle drop
    d.position.addScaledVector(d.userData.vel, dt);
    d.rotateOnAxis(new THREE.Vector3(0, 1, 0), d.userData.spin * dt);

    const basket = baskets[holeIndex];
    if (basket && d.position.distanceTo(basket.position) < basket.userData.radius) {
      scene.remove(d);
      discs.splice(i, 1);
      advanceHole();
      continue;
    }
    if (d.userData.life <= 0 || d.position.y < 0) {
      scene.remove(d);
      discs.splice(i, 1);
    }
  }
}

function frame() {
  update(Math.min(clock.getDelta(), 0.05));
  renderer.render(scene, camera);
  requestAnimationFrame(frame);
}

function startGame() {
  score = 0;
  holeIndex = 0;
  scoreEl.textContent = "0";
  ship.position.set(0, 40, 120);
  yaw = 0;
  pitch = -0.15;
  discs.splice(0).forEach((d) => scene.remove(d));
  layoutCourse();
  playing = true;
  startScreen.hidden = true;
  throwBtn.hidden = false;
  try {
    canvas.requestPointerLock?.();
  } catch (_) {
    /* pointer lock optional (mobile / headless) */
  }
}

startBtn.addEventListener("click", startGame);
throwBtn.addEventListener("click", (e) => {
  e.preventDefault();
  throwDisc();
});

addEventListener("keydown", (e) => {
  keys.add(e.key.toLowerCase());
  if (e.code === "Space") {
    e.preventDefault();
    throwDisc();
  }
});
addEventListener("keyup", (e) => keys.delete(e.key.toLowerCase()));

canvas.addEventListener("pointerdown", (e) => {
  pointerDown = true;
  lastX = e.clientX;
  lastY = e.clientY;
  if (playing) canvas.setPointerCapture?.(e.pointerId);
});
canvas.addEventListener("pointerup", () => {
  pointerDown = false;
});
canvas.addEventListener("pointermove", (e) => {
  if (!playing || !pointerDown) return;
  const dx = e.clientX - lastX;
  const dy = e.clientY - lastY;
  lastX = e.clientX;
  lastY = e.clientY;
  yaw -= dx * 0.004;
  pitch = THREE.MathUtils.clamp(pitch - dy * 0.0035, -1.1, 1.1);
});

addEventListener("resize", () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

layoutCourse();
frame();
