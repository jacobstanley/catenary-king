{-# LANGUAGE EmptyDataDecls #-}

module Ammo where

import Prelude
import FFI
import Math

------------------------------------------------------------------------

data CollisionConfiguration
data Dispatcher
data BroadphaseInterface
data ConstraintSolver
data DynamicsWorld

mkDefaultCollisionConfiguration :: Fay CollisionConfiguration
mkDefaultCollisionConfiguration = ffi "new Ammo.btDefaultCollisionConfiguration()"

mkCollisionDispatcher :: CollisionConfiguration -> Fay Dispatcher
mkCollisionDispatcher = ffi "new Ammo.btCollisionDispatcher(%1)"

mkDbvtBroadphase :: Fay BroadphaseInterface
mkDbvtBroadphase = ffi "new Ammo.btDbvtBroadphase()"

mkSequentialImpulseConstraintSolver :: Fay ConstraintSolver
mkSequentialImpulseConstraintSolver = ffi "new Ammo.btSequentialImpulseConstraintSolver()"

mkDiscreteDynamicsWorld
    :: Dispatcher
    -> BroadphaseInterface
    -> ConstraintSolver
    -> CollisionConfiguration
    -> Fay DynamicsWorld
mkDiscreteDynamicsWorld = ffi "new Ammo.btDiscreteDynamicsWorld(%1,%2,%3,%4)"

setGravity :: Double -> Double -> Double -> DynamicsWorld -> Fay ()
setGravity = ffi "%4.setGravity(new Ammo.btVector3(%1,%2,%3))"

addRigidBody :: DynamicsWorld -> RigidBody -> Fay ()
addRigidBody = ffi "%1.addRigidBody(%2)"

stepSimulation :: Double -> Int -> DynamicsWorld -> Fay ()
stepSimulation = ffi "%3.stepSimulation(%1,%2)"

------------------------------------------------------------------------

data BtVector3
data BtQuaternion

mkBtVector3 :: Double -> Double -> Double -> Fay BtVector3
mkBtVector3 = ffi "new Ammo.btVector3(%1,%2,%3)"

mkBtQuaternion :: Double -> Double -> Double -> Double -> Fay BtQuaternion
mkBtQuaternion = ffi "new Ammo.btQuaternion(%1,%2,%3,%4)"

vec2bt :: Vector3 -> Fay BtVector3
vec2bt (V x y z) = mkBtVector3 x y z

quat2bt :: Quaternion -> Fay BtQuaternion
quat2bt (Q x y z w) = mkBtQuaternion x y z w

bt2vec :: BtVector3 -> Fay Vector3
bt2vec = ffi "{ instance: 'Vector3', vx: %1.x(), vy: %1.y(), vz: %1.z() }"

bt2quat :: BtQuaternion -> Fay Quaternion
bt2quat = ffi "{ instance: 'Quaternion', qx: %1.x(), qy: %1.y(), qz: %1.z(), qw: %1.w() }"

------------------------------------------------------------------------

data Transform

mkTransform :: Fay Transform
mkTransform = ffi "new Ammo.btTransform()"

setIdentity :: Transform -> Fay ()
setIdentity = ffi "%1.setIdentity()"

bt_setOrigin :: BtVector3 -> Transform -> Fay ()
bt_setOrigin = ffi "%2.setOrigin(%1)"

bt_getOrigin :: Transform -> Fay BtVector3
bt_getOrigin = ffi "%1.getOrigin()"

getOrigin :: Transform -> Fay Vector3
getOrigin t = do
    v <- bt_getOrigin t >>= bt2vec
    return $ V (vx v) (vy v) (vz v)

setOrigin :: Vector3 -> Transform -> Fay ()
setOrigin v t = vec2bt v >>= \x -> bt_setOrigin x t

bt_setOrientation :: BtQuaternion -> Transform -> Fay ()
bt_setOrientation = ffi "%2.setRotation(%1)"

bt_getOrientation :: Transform -> Fay BtQuaternion
bt_getOrientation = ffi "%1.getRotation()"

getOrientation :: Transform -> Fay Quaternion
getOrientation t = do
    q <- bt_getOrientation t >>= bt2quat
    return $ Q (qx q) (qy q) (qz q) (qw q)

setOrientation :: Quaternion -> Transform -> Fay ()
setOrientation q t = quat2bt q >>= \x -> bt_setOrientation x t

------------------------------------------------------------------------

data Shape

mkBoxShape :: Double -> Double -> Double -> Fay Shape
mkBoxShape = ffi "new Ammo.btBoxShape(new Ammo.btVector3(%1,%2,%3))"

calculateLocalInertia :: Double -> Double -> Double -> Double -> Shape -> Fay ()
calculateLocalInertia = ffi "%5.calculateLocalInertia(%1,new Ammo.btVector3(%2,%3,%4))"

------------------------------------------------------------------------

data MotionState

mkDefaultMotionState :: Transform -> Fay MotionState
mkDefaultMotionState = ffi "new Ammo.btDefaultMotionState(%1)"

getWorldTransform :: MotionState -> Fay Transform
getWorldTransform = ffi "(function () { var t = new Ammo.btTransform(); %1.getWorldTransform(t); return t; })()"

------------------------------------------------------------------------

data RigidBody

mkRigidBody :: Double -> MotionState -> Shape -> Double -> Double -> Double -> Fay RigidBody
mkRigidBody = ffi "new Ammo.btRigidBody(new Ammo.btRigidBodyConstructionInfo(%1,%2,%3,new Ammo.btVector3(%4,%5,%6)))"

setDamping :: Double -> Double -> RigidBody -> Fay ()
setDamping = ffi "%3.setDamping(%1,%2)"

getMotionState :: RigidBody -> Fay MotionState
getMotionState = ffi "%1.getMotionState()"
