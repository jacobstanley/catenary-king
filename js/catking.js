(function(){
  var a3, t3, scene, renderer, camera, world, rigThree, rigAmmo, rigVolume, floatThree, render, update, logged, simulateBuoyancy, updateScene;
  import$(this, prelude);
  a3 = function(x, y, z){
    return new Ammo.btVector3(x, y, z);
  };
  t3 = function(x, y, z){
    return new THREE.Vector3(x, y, z);
  };
  scene = null;
  renderer = null;
  camera = null;
  world = null;
  rigThree = null;
  rigAmmo = null;
  rigVolume = null;
  floatThree = null;
  window.onload = function(){
    var width, height, x$, y$, z$, collisionCfg, dispatcher, broadphase, solver, near, far, zoom, left, top, z1$, floorG, floorM, z2$, floorShape, z3$, floorTransform, floorMass, floorInertia, floorMotionState, floorRbInfo, floorAmmo, oceanG, oceanM, z4$, floatG, z5$, floatM, rigG, z6$, rigM, z7$, rigMass, z8$, rigRotation, z9$, rigTransform, rigInertia, rigShape, rigMotionState, rigRbInfo, z10$;
    width = window.innerWidth;
    height = window.innerHeight;
    x$ = renderer = new THREE.WebGLRenderer({
      antialias: false
    });
    x$.setSize(width, height);
    x$.shadowMapEnabled = true;
    x$.shadowMapSoft = false;
    document.getElementById('viewport').appendChild(renderer.domElement);
    scene = new THREE.Scene;
    y$ = new THREE.DirectionalLight(0xffffff);
    y$.position.set(-300, 300, 500);
    y$.castShadow = true;
    scene.add(
    y$);
    z$ = new THREE.AmbientLight(0x777777);
    scene.add(
    z$);
    collisionCfg = new Ammo.btDefaultCollisionConfiguration;
    dispatcher = new Ammo.btCollisionDispatcher(collisionCfg);
    broadphase = new Ammo.btDbvtBroadphase();
    solver = new Ammo.btSequentialImpulseConstraintSolver();
    world = new Ammo.btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionCfg);
    world.setGravity(new Ammo.btVector3(0, 0, -9.8));
    near = 1;
    far = 1000;
    zoom = 0.5;
    left = -width * 0.5 * zoom;
    top = height * 0.5 * zoom;
    z1$ = camera = new THREE.OrthographicCamera(left, -left, top, -top, near, far);
    z1$.up = t3(0, 0, 1);
    z1$.position.set(-300, -300, 245);
    z1$.lookAt(t3(0, 0, 0));
    scene.add(
    z1$);
    floorG = new THREE.PlaneGeometry(200, 200);
    floorM = new THREE.MeshBasicMaterial({
      color: 0x333300
    });
    z2$ = new THREE.Mesh(floorG, floorM);
    z2$.receiveShadow = true;
    z2$.position.set(0, 0, -100);
    scene.add(
    z2$);
    floorShape = new Ammo.btStaticPlaneShape(a3(0, 0, 1), 0);
    z3$ = floorTransform = new Ammo.btTransform();
    z3$.setIdentity();
    z3$.setOrigin(a3(0, 0, -100));
    floorMass = 0;
    floorInertia = a3(0, 0, 0);
    floorMotionState = new Ammo.btDefaultMotionState(floorTransform);
    floorRbInfo = new Ammo.btRigidBodyConstructionInfo(floorMass, floorMotionState, floorShape, floorInertia);
    floorAmmo = new Ammo.btRigidBody(floorRbInfo);
    world.addRigidBody(floorAmmo);
    oceanG = new THREE.PlaneGeometry(200, 200);
    oceanM = new THREE.MeshBasicMaterial({
      color: 0x112244,
      transparent: true,
      opacity: 0.8
    });
    z4$ = new THREE.Mesh(oceanG, oceanM);
    z4$.receiveShadow = true;
    scene.add(
    z4$);
    floatG = new THREE.CubeGeometry(5, 5, 25);
    z5$ = floatM = new THREE.MeshLambertMaterial({
      color: 0xff0000
    });
    z5$.ambient = z5$.color;
    floatThree = new THREE.Mesh(floatG, floatM);
    rigG = new THREE.CubeGeometry(100, 100, 15);
    z6$ = rigM = new THREE.MeshLambertMaterial({
      color: 0x335533
    });
    z6$.ambient = z6$.color;
    z7$ = rigThree = new THREE.Mesh(rigG, rigM);
    z7$.castShadow = true;
    z7$.receiveShadow = true;
    z7$.useQuaternion = true;
    z7$.position.z = 100;
    scene.add(
    z7$);
    rigVolume = 100 * 100 * 15;
    rigMass = rigVolume * 700;
    z8$ = rigRotation = new Ammo.btQuaternion();
    z8$.setEuler(-pi / 8.0, pi / 16.0, 0);
    z9$ = rigTransform = new Ammo.btTransform();
    z9$.setIdentity();
    z9$.setOrigin(a3(0, 0, 100));
    z9$.setRotation(rigRotation);
    rigInertia = a3(0, 0, 0);
    rigShape = new Ammo.btBoxShape(a3(100, 100, 15));
    rigShape.calculateLocalInertia(rigMass, rigInertia);
    rigMotionState = new Ammo.btDefaultMotionState(rigTransform);
    rigRbInfo = new Ammo.btRigidBodyConstructionInfo(rigMass, rigMotionState, rigShape, rigInertia);
    z10$ = rigAmmo = new Ammo.btRigidBody(rigRbInfo);
    z10$.setDamping(0.2, 0.2);
    world.addRigidBody(rigAmmo);
    return requestAnimationFrame(render);
  };
  render = function(){
    update();
    renderer.render(scene, camera);
    return requestAnimationFrame(render);
  };
  update = function(){
    simulateBuoyancy();
    world.stepSimulation(1 / 60, 5);
    return updateScene();
  };
  logged = false;
  simulateBuoyancy = function(){
    var t, xy, floats, tf0, i$, len$, f, tf, fluidDensity, height, hheight, offset, volumeDisplaced, gravity, buoyancy, results$ = [];
    t = new Ammo.btTransform();
    rigAmmo.getMotionState().getWorldTransform(t);
    xy = 50 - 7.5;
    floats = [a3(xy, xy, 0), a3(xy, -xy, 0), a3(-xy, xy, 0), a3(-xy, -xy, 0)];
    tf0 = t.op_mul(floats[3]);
    floatThree.position.set(tf0.x(), tf0.y(), tf0.z());
    for (i$ = 0, len$ = floats.length; i$ < len$; ++i$) {
      f = floats[i$];
      tf = t.op_mul(f);
      fluidDensity = 1000;
      height = 15;
      hheight = height / 2.0;
      offset = height - (hheight + min(hheight, max(-hheight, tf.z())));
      volumeDisplaced = (rigVolume / floats.length) * (offset / hheight);
      if (volumeDisplaced <= 0) {
        continue;
      }
      gravity = -9.8;
      buoyancy = a3(0, 0, -gravity * fluidDensity * volumeDisplaced);
      results$.push(rigAmmo.applyForce(buoyancy, f));
    }
    return results$;
  };
  updateScene = function(){
    var t, pos, rot;
    t = new Ammo.btTransform();
    rigAmmo.getMotionState().getWorldTransform(t);
    pos = t.getOrigin();
    rot = t.getRotation();
    rigThree.position.set(pos.x(), pos.y(), pos.z());
    return rigThree.quaternion.set(rot.x(), rot.y(), rot.z(), rot.w());
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
