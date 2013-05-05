module CatenaryKing where

import Prelude

import DOM
import Math
import Three
import Ammo

------------------------------------------------------------------------

main :: Fay ()
main = do
    width  <- getWindowWidth
    height <- getWindowHeight

    renderer <- mkRenderer "viewport" width height
    camera   <- mkCamera width height
    lights   <- mkLights

    seafloor <- mkSeafloor
    ocean    <- mkOcean
    rig      <- mkRig

    scene <- mkScene
    scene `addChild` camera
    mapM_ (scene `addChild`) lights
    mapM_ (scene `addChild`) [seafloor, ocean, rig]

    world <- mkAmmoWorld
    rigB  <- mkRigBody
    world `addRigidBody` rigB

    animate $ do
        stepSimulation (1.0/60.0) 10 world

        motion          <- getMotionState rigB
        transform       <- getWorldTransform motion
        (V px py pz)    <- getOrigin transform
        (Q rx ry rz rw) <- getOrientation transform

        setPosition px py pz rig
        setRotation rx ry rz rw rig

        render scene camera renderer

-- update-scene = ->
--   t = new Ammo.bt-transform!
--   rig-ammo.get-motion-state!.get-world-transform t
--
--   pos = t.get-origin!
--   rot = t.get-rotation!
--   rig-three.position.set   pos.x!, pos.y!, pos.z!
--   rig-three.quaternion.set rot.x!, rot.y!, rot.z!, rot.w!

animate :: Fay () -> Fay ()
animate go = requestAnimationFrame (go >> animate go)

------------------------------------------------------------------------

mkRenderer :: String -> Int -> Int -> Fay Renderer
mkRenderer elemId width height = do
    renderer <- mkWebGLRenderer
    viewport <- getElementById elemId
    element  <- getDomElement renderer
    viewport `appendChild` element

    with renderer
      [ setRendererSize width height
      , setShadowMapSoft True
      , setShadowMapEnabled True
      ]

------------------------------------------------------------------------

mkCamera :: Int -> Int -> Fay Camera
mkCamera width height = do
    cam <- mkOrthographicCamera (-right) right top (-top) near far
    with cam
      [ setUp 0 0 1
      , setPosition (-300) (-300) 245
      , lookAt 0 0 0
      ]
  where
    near  = 1
    far   = 1000
    zoom  = 0.5
    right = fromIntegral width * 0.5 * zoom
    top   = fromIntegral height * 0.5 * zoom

------------------------------------------------------------------------

mkLights :: Fay [Light]
mkLights = do
    d <- mkDirectionalLight (hex 0xffffff)
    setPosition (-300) 300 500 d
    setCastShadow True d

    a <- mkAmbientLight (hex 0x777777)
    return [d, a]

------------------------------------------------------------------------

mkSeafloor :: Fay Mesh
mkSeafloor = do
    geom <- mkPlaneGeometry 200 200
    mat  <- mkMeshBasicMaterial (hex 0x333300)
    mesh <- mkMesh geom mat

    with mesh
      [ setReceiveShadow True
      , setPosition 0 0 (-100)
      ]

mkOcean :: Fay Mesh
mkOcean = do
    geom <- mkPlaneGeometry 200 200
    mat  <- mkMeshBasicMaterial (hex 0x112244)
    mesh <- mkMesh geom mat

    setOpacity 0.8 mat
    setReceiveShadow True mesh

    return mesh

mkRig :: Fay Mesh
mkRig = do
    geom <- mkCubeGeometry 100 100 15
    mat  <- mkMeshLambertMaterial (hex 0x335533)
    mesh <- mkMesh geom mat

    with mesh
      [ setCastShadow True
      , setReceiveShadow True
      , setUseQuaternion True
      , setPosition 0 0 100
      ]

------------------------------------------------------------------------
-- Ammo

mkAmmoWorld :: Fay DynamicsWorld
mkAmmoWorld = do
  collisionCfg <- mkDefaultCollisionConfiguration
  dispatcher   <- mkCollisionDispatcher collisionCfg
  broadphase   <- mkDbvtBroadphase
  solver       <- mkSequentialImpulseConstraintSolver
  world        <- mkDiscreteDynamicsWorld dispatcher broadphase solver collisionCfg

  setGravity 0 0 (-9.8) world

  return world

mkRigBody :: Fay RigidBody
mkRigBody = do
    transform <- mkTransform
    with transform
        [ setIdentity
        , setOrigin (V 0 0 100)
        , setOrientation $ euler 0 (pi/16.0) (-pi/8.0)
        ]

    shape <- mkBoxShape 100 100 15
    calculateLocalInertia mass 0 0 0 shape

    motionState <- mkDefaultMotionState transform

    body <- mkRigidBody mass motionState shape 0 0 0
    setDamping 0.2 0.2 body

    return body
  where
    volume = 100 * 100 * 15
    mass = volume * 700

------------------------------------------------------------------------
-- Utils

with :: a -> [a -> Fay ()] -> Fay a
with x fs = mapM_ ($ x) fs >> return x
