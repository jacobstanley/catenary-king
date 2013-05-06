import prelude

a3 = (x, y, z) -> new Ammo.bt-vector3 x, y, z
t3 = (x, y, z) -> new THREE.Vector3 x, y, z

scene    = null
renderer = null
camera   = null

world    = null

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
    #..shadow-camera-left    = -150
    #..shadow-camera-right   = 150
    #..shadow-camera-top     = 150
    #..shadow-camera-bottom  = -150
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
  new THREE.Mesh ocean-g, ocean-m
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
  rig-mass = rig-volume * 700
  rig-rotation = new Ammo.bt-quaternion!
    ..set-euler -pi/8.0, pi/16.0, pi/2.0
    #..set-euler 0, 0, 0
  rig-transform = new Ammo.bt-transform!
    ..set-identity!
    ..set-origin (a3 0, 0, 100)
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

  impulse = 1000000000 * diff

  if keys[KEY_UP]
    rig-ammo.apply-impulse (a3 0, impulse, 0), (a3 0 -80 0)
  if keys[KEY_DOWN]
    rig-ammo.apply-impulse (a3 0, -impulse, 0), (a3 0 -80 0)
  if keys[KEY_LEFT]
    rig-ammo.apply-impulse (a3 -impulse, 0, 0), (a3 80 80 0)
  if keys[KEY_RIGHT]
    rig-ammo.apply-impulse (a3 impulse, 0 0), (a3 -80 80 0)

  simulate-buoyancy diff
  world.step-simulation diff, 10

  update-scene!


alsdfkj = 0
logged = false
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
    offset = height - (hheight + min(hheight, max(-hheight, tf.z!)))
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
