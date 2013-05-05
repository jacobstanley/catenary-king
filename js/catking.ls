import prelude

vec3 = (x, y, z) -> new THREE.Vector3 x, y, z

scene    = null
renderer = null
camera   = null

rig = null
rig-volume = 0

gravity = vec3 0, 0, -9.8

window.onload = ->
  width  = window.inner-width
  height = window.inner-height

  renderer := new THREE.WebGLRenderer antialias: false
    ..setSize width, height
    ..shadow-map-enabled = true
    ..shadow-map-soft = true

  document.getElementById 'viewport' .appendChild renderer.domElement

  scene := new Physijs.Scene
    ..set-gravity gravity
    ..add-event-listener \update, update

  # Camera
  near = 1
  far  = 1000
  zoom = 0.5
  left = -width * 0.5 * zoom
  top  = height * 0.5 * zoom

  deg = (* 0.0174532925)

  #camera := new THREE.PerspectiveCamera fov, aspect, near, far
  camera := new THREE.OrthographicCamera left, -left, top, -top, near, far
      ..up = vec3 0, 0, 1
      ..position.set -300, -300, 245
      ..lookAt vec3 0, 0, 0

  scene.add camera

  # Floor
  floor-g = new THREE.PlaneGeometry 200, 200
  floor-m = new THREE.MeshBasicMaterial color: 0x333300
  floor = new Physijs.PlaneMesh floor-g, floor-m, 0
    ..receive-shadow = true
    ..position.set 0, 0, -100
  scene.add floor

  sea-g = new THREE.PlaneGeometry 200, 200
  sea-m = new THREE.MeshBasicMaterial color: 0x112244, transparent: true, opacity: 0.8
  sea = new THREE.Mesh sea-g, sea-m
  scene.add sea

  # Box
  rig-volume := 100 * 100 * 15
  rig-g = new THREE.CubeGeometry 100, 100, 15
  rig-m = new THREE.MeshLambertMaterial color: 0x335533
    ..ambient = ..color
  rig := new Physijs.BoxMesh rig-g, rig-m, rig-volume * 500
    ..cast-shadow = true
    ..position.z = 100
    #..rotation.set (deg 20), (deg 20), 0
  scene.add rig
  rig.set-damping 0.3, 0.3

  # Lights
  dir = new THREE.DirectionalLight 0xffffff
    ..position.set -1, 0, 2
    ..cast-shadow = true
  scene.add dir

  amb = new THREE.AmbientLight 0x777777
  scene.add amb

  requestAnimationFrame render

render = ->
  scene.simulate ``undefined``, 1 # run physics
  renderer.render scene, camera # render the scene
  requestAnimationFrame render

update = (x,y,z) ->
  rb = rig

  bs = rb.geometry.bounding-sphere
  offset = 15 - (7.5 + min(7.5, max(-7.5, rb.position.z)))
  submerged = offset / 15

  if submerged > 0
    fluid-density = 1000_kg_per_m3
    volume-displaced = rig-volume * submerged

    buoyancy = gravity
      .clone!
      .negate!
      .multiply-scalar fluid-density * volume-displaced

    rb.apply-central-force buoyancy
