(function(){
  var vec3, scene, renderer, camera, rig, rigVolume, gravity, render, update;
  import$(this, prelude);
  vec3 = function(x, y, z){
    return new THREE.Vector3(x, y, z);
  };
  scene = null;
  renderer = null;
  camera = null;
  rig = null;
  rigVolume = 0;
  gravity = vec3(0, 0, -9.8);
  window.onload = function(){
    var width, height, x$, y$, near, far, zoom, left, top, deg, z$, floorG, floorM, z1$, floor, seaG, seaM, sea, rigG, z2$, rigM, z3$, z4$, dir, amb;
    width = window.innerWidth;
    height = window.innerHeight;
    x$ = renderer = new THREE.WebGLRenderer({
      antialias: false
    });
    x$.setSize(width, height);
    x$.shadowMapEnabled = true;
    x$.shadowMapSoft = true;
    document.getElementById('viewport').appendChild(renderer.domElement);
    y$ = scene = new Physijs.Scene;
    y$.setGravity(gravity);
    y$.addEventListener('update', update);
    near = 1;
    far = 1000;
    zoom = 0.5;
    left = -width * 0.5 * zoom;
    top = height * 0.5 * zoom;
    deg = (function(it){
      return it * 0.0174532925;
    });
    z$ = camera = new THREE.OrthographicCamera(left, -left, top, -top, near, far);
    z$.up = vec3(0, 0, 1);
    z$.position.set(-300, -300, 245);
    z$.lookAt(vec3(0, 0, 0));
    scene.add(camera);
    floorG = new THREE.PlaneGeometry(200, 200);
    floorM = new THREE.MeshBasicMaterial({
      color: 0x333300
    });
    z1$ = floor = new Physijs.PlaneMesh(floorG, floorM, 0);
    z1$.receiveShadow = true;
    z1$.position.set(0, 0, -100);
    scene.add(floor);
    seaG = new THREE.PlaneGeometry(200, 200);
    seaM = new THREE.MeshBasicMaterial({
      color: 0x112244,
      transparent: true,
      opacity: 0.8
    });
    sea = new THREE.Mesh(seaG, seaM);
    scene.add(sea);
    rigVolume = 100 * 100 * 15;
    rigG = new THREE.CubeGeometry(100, 100, 15);
    z2$ = rigM = new THREE.MeshLambertMaterial({
      color: 0x335533
    });
    z2$.ambient = z2$.color;
    z3$ = rig = new Physijs.BoxMesh(rigG, rigM, rigVolume * 500);
    z3$.castShadow = true;
    z3$.position.z = 100;
    scene.add(rig);
    rig.setDamping(0.3, 0.3);
    z4$ = dir = new THREE.DirectionalLight(0xffffff);
    z4$.position.set(-1, 0, 2);
    z4$.castShadow = true;
    scene.add(dir);
    amb = new THREE.AmbientLight(0x777777);
    scene.add(amb);
    return requestAnimationFrame(render);
  };
  render = function(){
    scene.simulate(undefined, 1);
    renderer.render(scene, camera);
    return requestAnimationFrame(render);
  };
  update = function(x, y, z){
    var rb, bs, offset, submerged, fluidDensity, volumeDisplaced, buoyancy;
    rb = rig;
    bs = rb.geometry.boundingSphere;
    offset = 15 - (7.5 + min(7.5, max(-7.5, rb.position.z)));
    submerged = offset / 15;
    if (submerged > 0) {
      fluidDensity = 1000;
      volumeDisplaced = rigVolume * submerged;
      buoyancy = gravity.clone().negate().multiplyScalar(fluidDensity * volumeDisplaced);
      return rb.applyCentralForce(buoyancy);
    }
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
