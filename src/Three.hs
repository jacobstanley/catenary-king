{-# LANGUAGE EmptyDataDecls #-}

module Three where

import FFI
import DOM

-------------------------------------------------------------------------

newtype Color = Color { unColor :: Int }

hex :: Int -> Color
hex x | x >= 0x0 && x <= 0xffffff = Color x
      | otherwise = error ("Invalid color: " ++ show x)

-------------------------------------------------------------------------

data Renderer

mkWebGLRenderer :: Fay Renderer
mkWebGLRenderer = ffi "new THREE.WebGLRenderer()"

setRendererSize :: Int -> Int -> Renderer -> Fay ()
setRendererSize = ffi "%3.setSize(%1,%2)"

setShadowMapEnabled :: Bool -> Renderer -> Fay ()
setShadowMapEnabled = ffi "%2.shadowMapEnabled = %1"

setShadowMapSoft :: Bool -> Renderer -> Fay ()
setShadowMapSoft = ffi "%2.shadowMapSoft = %1"

getDomElement :: Renderer -> Fay Element
getDomElement = ffi "%1.domElement"

render :: Scene -> Camera -> Renderer -> Fay ()
render = ffi "%3.render(%1,%2)"

------------------------------------------------------------------------

class Object3D a

addChild :: (Object3D a, Object3D b) => a -> b -> Fay ()
addChild = ffi "%1.add(%2)"

setPosition :: Object3D a => Double -> Double -> Double -> a -> Fay ()
setPosition = ffi "%4.position.set(%1,%2,%3)"

setRotation :: Object3D a => Double -> Double -> Double -> Double -> a -> Fay ()
setRotation = ffi "%5.rotation.set(%1,%2,%3,%4)"

setCastShadow :: Object3D a => Bool -> a -> Fay ()
setCastShadow = ffi "%2.castShadow = %1"

setReceiveShadow :: Object3D a => Bool -> a -> Fay ()
setReceiveShadow = ffi "%2.receiveShadow = %1"

setUseQuaternion :: Object3D a => Bool -> a -> Fay ()
setUseQuaternion = ffi "%2.useQuaternion = %1"

-------------------------------------------------------------------------

data Scene
instance Object3D Scene

mkScene :: Fay Scene
mkScene = ffi "new THREE.Scene()"

-------------------------------------------------------------------------

data Camera
instance Object3D Camera

mkPerspectiveCamera :: Double -> Double -> Double -> Double -> Fay Camera
mkPerspectiveCamera = ffi "new THREE.PerspectiveCamera(%1,%2,%3,%4)"

mkOrthographicCamera :: Double -> Double -> Double
                     -> Double -> Double -> Double -> Fay Camera
mkOrthographicCamera = ffi "new THREE.OrthographicCamera(%1,%2,%3,%4,%5,%6)"

setUp :: Double -> Double -> Double -> Camera ->  Fay ()
setUp = ffi "%4.up = new THREE.Vector3(%1,%2,%3)"

lookAt :: Double -> Double -> Double -> Camera ->  Fay ()
lookAt = ffi "%4.lookAt(new THREE.Vector3(%1,%2,%3))"

-------------------------------------------------------------------------

data Light
instance Object3D Light

mkAmbientLight :: Color -> Fay Light
mkAmbientLight = ffi "new THREE.AmbientLight(%1)"

mkDirectionalLight :: Color -> Fay Light
mkDirectionalLight = ffi "new THREE.DirectionalLight(%1)"

-------------------------------------------------------------------------

data Mesh
instance Object3D Mesh

mkMesh :: Geometry -> Material -> Fay Mesh
mkMesh = ffi "new THREE.Mesh(%1,%2)"

-------------------------------------------------------------------------

data Geometry

mkPlaneGeometry :: Double -> Double -> Fay Geometry
mkPlaneGeometry = ffi "new THREE.PlaneGeometry(%1,%2)"

mkCubeGeometry :: Double -> Double -> Double -> Fay Geometry
mkCubeGeometry = ffi "new THREE.CubeGeometry(%1,%2,%3)"

-------------------------------------------------------------------------

data Material

mkMeshBasicMaterial :: Color -> Fay Material
mkMeshBasicMaterial = ffi "new THREE.MeshBasicMaterial({ color: %1 })"

mkMeshLambertMaterial :: Color -> Fay Material
mkMeshLambertMaterial = ffi "new THREE.MeshBasicMaterial({ color: %1, ambient: %1 })"

setOpacity :: Double -> Material -> Fay ()
setOpacity x m = do
    setTransparent (x < 1) m
    setOpacity' x m

setOpacity' :: Double -> Material -> Fay ()
setOpacity' = ffi "%2.opacity = %1"

setTransparent :: Bool -> Material -> Fay ()
setTransparent = ffi "%2.transparent = %1"
