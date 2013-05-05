import prelude

a3 = (x, y, z) -> new Ammo.bt-vector3 x, y, z
t3 = (x, y, z) -> new THREE.Vector3 x, y, z

scene    = null
renderer = null
camera   = null

world    = null

rig-three  = null
rig-ammo   = null
rig-volume = null

float-three = null

window.onload = ->
  width  = window.inner-width
  height = window.inner-height

  # Renderer
  renderer := new THREE.WebGLRenderer antialias: false
    ..set-size width, height
    ..shadow-map-enabled = true
    ..shadow-map-soft = false
  document
    .get-element-by-id \viewport
    .append-child renderer.dom-element

  # Scene
  scene := new THREE.Scene

  # Lights
  new THREE.DirectionalLight 0xffffff
    #..shadow-camera-visible = true
    #..shadow-camera-left    = -150
    #..shadow-camera-right   = 150
    #..shadow-camera-top     = 150
    #..shadow-camera-bottom  = -150
    ..position.set -300, 300, 500
    ..cast-shadow = true
    .. |> scene.add

  new THREE.AmbientLight 0x777777
    .. |> scene.add

  # Ammo
  collision-cfg = new Ammo.bt-default-collision-configuration
  dispatcher    = new Ammo.bt-collision-dispatcher collision-cfg
  broadphase    = new Ammo.bt-dbvt-broadphase!
  solver        = new Ammo.bt-sequential-impulse-constraint-solver!

  world := new Ammo.bt-discrete-dynamics-world dispatcher, broadphase, solver, collision-cfg
  world.set-gravity new Ammo.bt-vector3 0, 0, -9.8

  # Camera
  near = 1
  far  = 1000
  zoom = 0.5
  left = -width * 0.5 * zoom
  top  = height * 0.5 * zoom

  camera := new THREE.OrthographicCamera left, -left, top, -top, near, far
      ..up = t3 0, 0, 1
      ..position.set -300, -300, 245
      ..lookAt t3 0, 0, 0
      .. |> scene.add

  # Floor
  floor-g = new THREE.PlaneGeometry 200, 200
  floor-m = new THREE.MeshBasicMaterial color: 0x333300
  new THREE.Mesh floor-g, floor-m
    ..receive-shadow = true
    ..position.set 0, 0, -100
    .. |> scene.add

  floor-shape = new Ammo.bt-static-plane-shape (a3 0, 0, 1), 0
  floor-transform = new Ammo.bt-transform!
    ..set-identity!
    ..set-origin a3 0, 0, -100
  floor-mass = 0
  floor-inertia = a3 0, 0, 0
  floor-motion-state = new Ammo.bt-default-motion-state floor-transform
  floor-rb-info = new Ammo.bt-rigid-body-construction-info floor-mass, floor-motion-state, floor-shape, floor-inertia
  floor-ammo = new Ammo.bt-rigid-body floor-rb-info
  world.add-rigid-body floor-ammo

  # Ocean
  ocean-g = new THREE.PlaneGeometry 200, 200
  ocean-m = new THREE.MeshBasicMaterial color: 0x112244, transparent: true, opacity: 0.8
  new THREE.Mesh ocean-g, ocean-m
    ..receive-shadow = true
    .. |> scene.add

  # Float
  float-g = new THREE.CubeGeometry 5, 5, 25
  float-m = new THREE.MeshLambertMaterial color: 0xff0000
    ..ambient = ..color
  float-three := new THREE.Mesh float-g, float-m
    #  .. |> scene.add

  # Box
  rig-g = new THREE.CubeGeometry 100, 100, 15
  rig-m = new THREE.MeshLambertMaterial color: 0x335533
    ..ambient = ..color
  rig-three := new THREE.Mesh rig-g, rig-m
    ..cast-shadow = true
    ..receive-shadow = true
    ..use-quaternion = true
    ..position.z = 100
    .. |> scene.add

  rig-volume := 100 * 100 * 15
  rig-mass = rig-volume * 700
  rig-rotation = new Ammo.bt-quaternion!
    ..set-euler -pi/8.0, pi/16.0, 0
  rig-transform = new Ammo.bt-transform!
    ..set-identity!
    ..set-origin (a3 0, 0, 100)
    ..set-rotation rig-rotation
  rig-inertia = a3 0, 0, 0
  rig-shape = new Ammo.bt-box-shape a3 100, 100, 15
  rig-shape.calculate-local-inertia rig-mass, rig-inertia
  rig-motion-state = new Ammo.bt-default-motion-state rig-transform
  rig-rb-info = new Ammo.bt-rigid-body-construction-info rig-mass, rig-motion-state, rig-shape, rig-inertia
  rig-ammo := new Ammo.bt-rigid-body rig-rb-info
    ..set-damping 0.2, 0.2
  world.add-rigid-body rig-ammo

  request-animation-frame render

render = ->
  update!
  renderer.render scene, camera
  request-animation-frame render

time = new Date!.get-time!
update = ->
  simulate-buoyancy!

  curr = new Date!.get-time!
  diff = (curr - time) / 1000.0
  time := curr

  world.step-simulation diff, 10
  update-scene!

logged = false
simulate-buoyancy = ->
  t = new Ammo.bt-transform!
  rig-ammo.get-motion-state!.get-world-transform t

  xy = 50 - 7.5
  floats =
    a3  xy,  xy, 0
    a3  xy, -xy, 0
    a3 -xy,  xy, 0
    a3 -xy, -xy, 0

  tf0 = t.op_mul floats[3]
  float-three.position.set tf0.x!, tf0.y!, tf0.z!

  for f in floats
    tf = t.op_mul f

    fluid-density = 1000_kg_per_m3

    height = 15
    hheight = height/2.0
    offset = height - (hheight + min(hheight, max(-hheight, tf.z!)))
    volume-displaced = (rig-volume/floats.length) * (offset / hheight)

    if volume-displaced <= 0
      continue

    gravity = -9.8
    buoyancy = a3 0, 0, -gravity * fluid-density * volume-displaced

    rig-ammo.apply-force buoyancy, f


update-scene = ->
  t = new Ammo.bt-transform!
  rig-ammo.get-motion-state!.get-world-transform t

  pos = t.get-origin!
  rot = t.get-rotation!
  rig-three.position.set   pos.x!, pos.y!, pos.z!
  rig-three.quaternion.set rot.x!, rot.y!, rot.z!, rot.w!
