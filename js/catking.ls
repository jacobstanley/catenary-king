import prelude

a3 = (x, y, z) -> new Ammo.bt-vector3 x, y, z
t3 = (x, y, z) -> new THREE.Vector3 x, y, z

ac3 = (v) -> new Ammo.bt-vector3 v.x!, v.y!, v.z!

scene    = null
renderer = null
camera   = null

world    = null

ocean = null
waterline = 0

rig-three  = null
#rig-three2 = null
rig-ammo   = null
rig-volume = null

float-three = []

keys      = {}
KEY_LEFT  = 37
KEY_UP    = 38
KEY_RIGHT = 39
KEY_DOWN  = 40

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
    #..shadow-camera-left    = -300
    #..shadow-camera-right   = 300
    #..shadow-camera-top     = 300
    #..shadow-camera-bottom  = -300
    ..shadow-map-width = 2048
    ..shadow-map-height = 2048
    ..position.set -300, 300, 500
    ..cast-shadow = true
    .. |> scene.add

  new THREE.AmbientLight 0x111111
    .. |> scene.add

  # Ammo
  collision-cfg = new Ammo.bt-default-collision-configuration
  dispatcher    = new Ammo.bt-collision-dispatcher collision-cfg
  broadphase    = new Ammo.bt-dbvt-broadphase!
  solver        = new Ammo.bt-sequential-impulse-constraint-solver!

  world := new Ammo.bt-discrete-dynamics-world dispatcher, broadphase, solver, collision-cfg
  world.set-gravity new Ammo.bt-vector3 0, 0, -9.8

  # Camera
  near = 0
  far  = 3000
  zoom = 1.0
  left = -width * 0.5 * zoom
  top  = height * 0.5 * zoom

  camera := new THREE.OrthographicCamera left, -left, top, -top, near, far
      ..up = t3 0, 0, 1
      ..position.set -900, -900, 735
      ..lookAt t3 0, 0, 0
      .. |> scene.add

  # Floor
  floor-g = new THREE.PlaneGeometry 2000, 2000
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
  ocean-g = new THREE.PlaneGeometry 2000, 2000
  ocean-m = new THREE.MeshBasicMaterial color: 0x112244, transparent: true, opacity: 0.8
  ocean := new THREE.Mesh ocean-g, ocean-m
    ..receive-shadow = true
    .. |> scene.add

  # Float
  float-g = new THREE.CubeGeometry 5, 5, 25
  mesh = (hex) -> new THREE.MeshLambertMaterial color: hex
  float-three := [
    new THREE.Mesh float-g, mesh 0xff0000
    new THREE.Mesh float-g, mesh 0x00ff00
    new THREE.Mesh float-g, mesh 0x0000ff
    new THREE.Mesh float-g, mesh 0xffff00
  ]

  for f in float-three
    scene.add f

  # Box
  #rig-g = new THREE.CubeGeometry 85, 85, 15
  #rig-m = new THREE.MeshLambertMaterial color: 0x335533
  #  ..ambient = ..color
  #rig-three2 := new THREE.Mesh rig-g, rig-m
  #  ..cast-shadow = true
  #  ..receive-shadow = true
  #  ..use-quaternion = true
  #  ..position.z = 100
  #  .. |> scene.add

  loader = new THREE.ColladaLoader!
  loader.load 'dae/rig.dae' (dae) ->
    rig-three := dae.scene
      .. |> all-the-shadows
      ..use-quaternion = true
      ..position.z = 100
      .. |> scene.add

  rig-volume := 85 * 85 * 15
  rig-mass = rig-volume * 1100
  rig-rotation = new Ammo.bt-quaternion!
    #..set-euler -pi/8.0, pi/16.0, pi/2.0
    ..set-euler 0, 0, 0
  rig-transform = new Ammo.bt-transform!
    ..set-identity!
    ..set-origin (a3 0, 0, 0)
    ..set-rotation rig-rotation
  rig-inertia = a3 0, 0, 0
  rig-shape = new Ammo.bt-box-shape a3 85/2.0, 85/2.0, 15/2.0
  rig-shape.calculate-local-inertia rig-mass, rig-inertia
  rig-motion-state = new Ammo.bt-default-motion-state rig-transform
  rig-rb-info = new Ammo.bt-rigid-body-construction-info rig-mass, rig-motion-state, rig-shape, rig-inertia
  rig-ammo := new Ammo.bt-rigid-body rig-rb-info
    ..set-damping 0.2, 0.2
  world.add-rigid-body rig-ammo

  $ document .on 'keydown' (e) ->
    keys[e.which] = true

  $ document .on 'keyup' (e) ->
    delete keys[e.which]

  request-animation-frame render

render = ->
  if rig-three
    update!
    renderer.render scene, camera
  request-animation-frame render

time = new Date!.get-time!
update = ->
  curr = new Date!.get-time!
  diff = (curr - time) / 1000.0
  time := curr

  dt = min diff, (5/60.0)
  apply-user-input dt
  update-ocean dt
  simulate-buoyancy dt
  world.step-simulation dt, 5

  update-scene!

apply-user-input = (dt) ->
  world-trans = new Ammo.bt-transform!
  rig-ammo.get-motion-state!.get-world-transform world-trans

  impulse-factor = 1000000000 * dt
  impulse-mag = 0

  outboard-local = a3 0, -40, -10
  outboard-world = world-trans.op_mul outboard-local

  if outboard-world.z! > waterline
    # outboard's not in the water m8!
    return

  cog = rig-ammo.get-center-of-mass-position!
  outboard-rel = (ac3 outboard-world).op_sub cog

  outboard-yaw = 0

  if keys[KEY_LEFT]
    outboard-yaw -= pi/16.0
  if keys[KEY_RIGHT]
    outboard-yaw += pi/16.0
  if keys[KEY_UP]
    impulse-mag += impulse-factor
  if keys[KEY_DOWN]
    impulse-mag -= impulse-factor

  if impulse-mag == 0
    return

  world-rot = new Ammo.bt-transform!
    ..set-rotation world-trans.get-rotation!
  outboard-rot = new Ammo.bt-transform!
    ..set-rotation (new Ammo.bt-quaternion 0, 0, outboard-yaw)
  final-rot = new Ammo.bt-transform!
    ..mult world-rot, outboard-rot

  impulse = final-rot.op_mul (a3 0, impulse-mag, 0)

  rig-ammo.apply-impulse impulse, outboard-rel
  #rig-ammo.apply-central-impulse (a3 0, 0, impulse-mag * 0.1)

ocean-time = 0
update-ocean = (dt) ->
  ocean-time += dt

  swell = 20m
  period = 15s
  waterline := swell * sin (ocean-time/(period/4.0))
  ocean.position.z = waterline

simulate-buoyancy = (dt) ->
  t = new Ammo.bt-transform!
  rig-ammo.get-motion-state!.get-world-transform t

  xy = 35 - 7.5
  floats = [
    a3  xy,  xy, 0
    a3  xy, -xy, 0
    a3 -xy,  xy, 0
    a3 -xy, -xy, 0
  ]

  i = 0
  for f in floats
    tf = t.op_mul f

    float-three[i].position.set tf.x!, tf.y!, tf.z!
    i++

    fluid-density = 1000_kg_per_m3

    height = 25
    hheight = height/2.0
    water-diff = tf.z! - waterline
    offset = height - (hheight + min(hheight, max(-hheight, water-diff)))
    volume-displaced = (rig-volume/floats.length) * (offset / hheight)

    if volume-displaced <= 0
      continue

    pos = rig-ammo.get-center-of-mass-position!
    rf = tf.op_sub pos

    buoyancy = 9.8 * fluid-density * volume-displaced * dt

    rig-ammo.apply-impulse (a3 0, 0, buoyancy), rf

update-scene = ->
  t = new Ammo.bt-transform!
  rig-ammo.get-motion-state!.get-world-transform t

  pos = t.get-origin!
  rot = t.get-rotation!
  rig-three.position.set   pos.x!, pos.y!, pos.z!
  rig-three.quaternion.set rot.x!, rot.y!, rot.z!, rot.w!
  #rig-three2.position.set   pos.x!, pos.y!, pos.z!
  #rig-three2.quaternion.set rot.x!, rot.y!, rot.z!, rot.w!

all-the-shadows = (obj) ->
  obj
    ..cast-shadow = true
    ..receive-shadow = true
  for child in obj.children
    all-the-shadows child
