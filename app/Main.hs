module Main where

import Network.Wai.Handler.Warp (run)
import Endpoints (app)

main :: IO ()
main =
  run 8080 app
