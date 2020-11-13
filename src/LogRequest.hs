{-# LANGUAGE OverloadedStrings #-}

module LogRequest where

import Network.Wai (Request)
import System.Directory (createDirectoryIfMissing)
import System.FilePath.Posix (takeDirectory)
import Data.Time

writeLog :: Request -> IO ()
writeLog req = do
 let path = "var/log/server.log"
 createDirectoryIfMissing True $ takeDirectory path
 time <- getCurrentTime
 let printableReq = 
      "time: " ++ show time ++ "\n"
      ++ show req ++ "\n-----------\n"
 appendFile path printableReq
 