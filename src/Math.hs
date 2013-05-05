module Math where

import Prelude

------------------------------------------------------------------------

data Vector3 = V {
    vx :: !Double
  , vy :: !Double
  , vz :: !Double
  }

data Quaternion = Q {
    qx :: !Double
  , qy :: !Double
  , qz :: !Double
  , qw :: !Double
  }

euler :: Double -> Double -> Double -> Quaternion
euler yaw pitch roll = Q x y z w
  where
    x = sinRoll * cosPitch * cosYaw - cosRoll * sinPitch * sinYaw
    y = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw
    z = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw
    w = cosRoll * cosPitch * cosYaw + sinRoll * sinPitch * sinYaw

    cosYaw    = cos halfYaw
    sinYaw    = sin halfYaw
    cosPitch  = cos halfPitch
    sinPitch  = sin halfPitch
    cosRoll   = cos halfRoll
    sinRoll   = sin halfRoll

    halfYaw   = yaw * 0.5
    halfPitch = pitch * 0.5
    halfRoll  = roll * 0.5
