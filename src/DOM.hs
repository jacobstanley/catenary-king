{-# LANGUAGE EmptyDataDecls #-}

module DOM where

import FFI

------------------------------------------------------------------------

getWindowWidth :: Fay Int
getWindowWidth = ffi "window.innerWidth"

getWindowHeight :: Fay Int
getWindowHeight = ffi "window.innerHeight"

requestAnimationFrame :: Fay () -> Fay ()
requestAnimationFrame = ffi "window.requestAnimationFrame(%1)"

------------------------------------------------------------------------

data Element

getElementById :: String -> Fay Element
getElementById = ffi "window.document.getElementById(%1)"

appendChild :: Element -> Element -> Fay ()
appendChild = ffi "%1.appendChild(%2)"
