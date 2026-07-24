/* ── Pebble Platform · Accessible Scroll · app.js ── */
// NOTE: these bare specifiers are resolved by the <script type="importmap">
// in index.html. STLLoader.js itself does `import ... from 'three'`, so the
// import map is REQUIRED — without it the whole module fails to load.
import * as THREE from 'three';
import { STLLoader } from 'three/addons/loaders/STLLoader.js';

const STL_URL = 'pebble-top-case.stl';

// Shared: load STL, centre it, scale it, orient it upright
function loadModel(group, color = 0x0070BA) {
  const loader = new STLLoader();
  loader.load(
    STL_URL,
    function (geometry) {
      geometry.computeBoundingBox();
      const center = new THREE.Vector3();
      geometry.boundingBox.getCenter(center);
      geometry.translate(-center.x, -center.y, -center.z);
      geometry.computeVertexNormals();

      // Auto-fit: scale the model so its largest dimension is a fixed size,
      // so the camera framing works no matter what the STL's units are.
      const size = new THREE.Vector3();
      geometry.boundingBox.getSize(size);
      const maxDim = Math.max(size.x, size.y, size.z) || 1;
      const scale = 0.11 / maxDim;

      const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.38, metalness: 0.08 });
      const mesh = new THREE.Mesh(geometry, mat);
      mesh.scale.setScalar(scale);
      // OpenSCAD is Z-up; Three.js is Y-up → rotate -90° around X
      mesh.rotation.x = -Math.PI / 2;

      group.add(mesh);
    },
    undefined,
    function (err) {
      console.error('[Accessible Scroll] Could not load ' + STL_URL, err);
      showModelError(group);
    }
  );
}

// Visible fallback so a missing file is obvious instead of a blank box
function showModelError(group) {
  const canvasWrap = document.querySelector('.hero-canvas-wrap, .cad-viewport');
  document.querySelectorAll('.hero-canvas-wrap, .cad-viewport').forEach(function (wrap) {
    if (wrap.querySelector('.model-error')) return;
    const msg = document.createElement('div');
    msg.className = 'model-error';
    msg.textContent = '3D model could not load — check that pebble-top-case.stl is uploaded next to index.html';
    wrap.appendChild(msg);
  });
}

// ════════════════════════════════════════════════════════════
//  HERO CANVAS — rotating real STL model
// ════════════════════════════════════════════════════════════
(function setupHero() {
  const canvas = document.getElementById('heroCanvas');
  if (!canvas) return;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));

  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#0D1B2E');

  const camera = new THREE.PerspectiveCamera(36, 1, 0.001, 10);
  camera.position.set(0.10, 0.06, 0.25);
  camera.lookAt(0, 0, 0);

  scene.add(new THREE.AmbientLight(0xffffff, 0.55));
  const d1 = new THREE.DirectionalLight(0xffffff, 0.9);
  d1.position.set(0.3, 0.6, 0.5); scene.add(d1);
  const d2 = new THREE.DirectionalLight(0x88BBFF, 0.35);
  d2.position.set(-0.3, -0.1, 0.4); scene.add(d2);
  const rim = new THREE.DirectionalLight(0x0070BA, 0.4);
  rim.position.set(0, 0.2, -0.5); scene.add(rim);

  const group = new THREE.Group();
  scene.add(group);
  loadModel(group, 0x0070BA);

  function resizeHero() {
    const w = canvas.parentElement.clientWidth;
    const h = Math.min(w * 0.75, 500);
    renderer.setSize(w, h);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  resizeHero();
  window.addEventListener('resize', resizeHero);

  let dragging = false, lx = 0, ly = 0, rotY = 0.4, rotX = -0.15, autoRot = true;
  canvas.addEventListener('mousedown', e => { dragging = true; autoRot = false; lx = e.clientX; ly = e.clientY; });
  window.addEventListener('mouseup', () => { dragging = false; });
  window.addEventListener('mousemove', e => {
    if (!dragging) return;
    rotY += (e.clientX - lx) * 0.007; lx = e.clientX;
    rotX += (e.clientY - ly) * 0.007; ly = e.clientY;
    rotX = Math.max(-0.8, Math.min(0.8, rotX));
  });

  (function loop() {
    requestAnimationFrame(loop);
    if (autoRot) rotY += 0.006;
    group.rotation.y = rotY;
    group.rotation.x = rotX;
    renderer.render(scene, camera);
  })();
})();

// ════════════════════════════════════════════════════════════
//  CAD MULTI-VIEW CANVAS
// ════════════════════════════════════════════════════════════
(function setupCadViewer() {
  const canvas = document.getElementById('cadCanvas');
  if (!canvas) return;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#0B1827');

  const grid = new THREE.GridHelper(0.3, 12, 0x1a3a5c, 0x112235);
  grid.position.y = -0.025; scene.add(grid);

  const camera = new THREE.PerspectiveCamera(36, 1, 0.001, 10);

  scene.add(new THREE.AmbientLight(0xffffff, 0.5));
  const key = new THREE.DirectionalLight(0xffffff, 0.95);
  key.position.set(0.4, 0.7, 0.5); key.castShadow = true; scene.add(key);
  const fill = new THREE.DirectionalLight(0xBBCCFF, 0.3);
  fill.position.set(-0.3, 0.1, 0.4); scene.add(fill);
  const back = new THREE.DirectionalLight(0x0070BA, 0.35);
  back.position.set(0, 0.3, -0.5); scene.add(back);

  const group = new THREE.Group();
  scene.add(group);
  loadModel(group, 0x0070BA);

  const VIEWS = {
    iso:    { pos: [0.14, 0.10, 0.24], up: [0, 1, 0] },
    front:  { pos: [0,    0.04, 0.30], up: [0, 1, 0] },
    back:   { pos: [0,    0.04,-0.30], up: [0, 1, 0] },
    side:   { pos: [0.30, 0.04, 0],    up: [0, 1, 0] },
    top:    { pos: [0,    0.32, 0],    up: [0, 0,-1] },
    bottom: { pos: [0,   -0.32, 0],    up: [0, 0, 1] }
  };

  let rotX = 0, rotY = 0, zoom = 1.0;
  let targetPos = [...VIEWS.iso.pos];
  let targetUp  = [...VIEWS.iso.up];

  function applyView(name) {
    if (!VIEWS[name]) return;
    targetPos = [...VIEWS[name].pos];
    targetUp  = [...VIEWS[name].up];
    rotX = 0; rotY = 0;
    group.rotation.set(0, 0, 0);
    document.querySelectorAll('.view-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-view="${name}"]`)?.classList.add('active');
  }

  let dragging = false, lx = 0, ly = 0;
  canvas.addEventListener('mousedown', e => { dragging = true; lx = e.clientX; ly = e.clientY; });
  window.addEventListener('mouseup', () => { dragging = false; });
  window.addEventListener('mousemove', e => {
    if (!dragging) return;
    rotY += (e.clientX - lx) * 0.007; lx = e.clientX;
    rotX += (e.clientY - ly) * 0.007; ly = e.clientY;
    rotX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, rotX));
  });

  let touchLx = 0, touchLy = 0;
  canvas.addEventListener('touchstart', e => { touchLx = e.touches[0].clientX; touchLy = e.touches[0].clientY; }, { passive: true });
  canvas.addEventListener('touchmove', e => {
    rotY += (e.touches[0].clientX - touchLx) * 0.007; touchLx = e.touches[0].clientX;
    rotX += (e.touches[0].clientY - touchLy) * 0.007; touchLy = e.touches[0].clientY;
    rotX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, rotX));
  }, { passive: true });

  canvas.addEventListener('wheel', e => {
    zoom = Math.max(0.4, Math.min(2.8, zoom + e.deltaY * 0.001));
    e.preventDefault();
  }, { passive: false });

  document.querySelectorAll('[data-view]').forEach(btn => {
    btn.addEventListener('click', () => applyView(btn.dataset.view));
  });
  document.getElementById('zoomIn')?.addEventListener('click', () => { zoom = Math.max(0.4, zoom - 0.2); });
  document.getElementById('zoomOut')?.addEventListener('click', () => { zoom = Math.min(2.8, zoom + 0.2); });
  document.getElementById('resetView')?.addEventListener('click', () => { zoom = 1.0; applyView('iso'); });

  applyView('iso');

  function resizeCad() {
    const w = canvas.parentElement.clientWidth;
    const h = Math.min(Math.max(w * 0.55, 300), 520);
    renderer.setSize(w, h);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  resizeCad();
  window.addEventListener('resize', resizeCad);

  const camPos = new THREE.Vector3(...targetPos);

  (function loop() {
    requestAnimationFrame(loop);
    const tPos = new THREE.Vector3(...targetPos).multiplyScalar(zoom);
    camPos.lerp(tPos, 0.12);
    camera.position.copy(camPos);
    camera.up.lerp(new THREE.Vector3(...targetUp), 0.15);
    camera.lookAt(0, 0, 0);
    if (dragging || Math.abs(rotX) > 0.001 || Math.abs(rotY) > 0.001) {
      group.rotation.x = rotX;
      group.rotation.y = rotY;
    }
    renderer.render(scene, camera);
  })();
})();
