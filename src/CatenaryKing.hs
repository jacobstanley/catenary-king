module CatenaryKing where

import Prelude

import DOM
import Three

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
    rig      <- mkOilRig

    scene <- mkScene
    scene `addChild` camera
    mapM_ (scene `addChild`) lights
    mapM_ (scene `addChild`) [seafloor, ocean, rig]

    animate $ do
        render scene camera renderer

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

mkOilRig :: Fay Mesh
mkOilRig = do
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
-- Utils

with :: a -> [a -> Fay ()] -> Fay a
with x fs = mapM_ ($ x) fs >> return x
